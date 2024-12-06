#!/bin/bash
beagle_exec_path=$(readlink -f bin/beagle.29Oct24.c8e.jar)
eagle_exec_path=$(readlink -f bin/eagle_v2.4.1)
minimac_exec_path=$(readlink -f bin/minimac4.1.6)
impute_exec_path=$(readlink -f bin/impute5_v1.2.0)
shapeit_exec_path=$(readlink -f bin/shapeit_phase_common_staticv5.1.1)

load_beagle() {
  if ! java -version 2>&1 | grep 1.8 >/dev/null; then
    echo 'Java 1.8 is required' >&2
    exit 1
  fi
  tool="java -jar "$beagle_exec_path
  if ! $tool >/dev/null; then
    echo 'Beagle is not found' >&2
    exit 1
  fi
}

load_eagle() {
  tool=$eagle_exec_path
  if ! $tool --help >/dev/null; then
    echo 'Eagle is not found' >&2
    exit 1
  fi
}

load_minimac() {
  tool=$minimac_exec_path
  if ! $tool --help >/dev/null; then
    echo 'Minimac is not found' >&2
    exit 1
  fi
}

load_impute() {
  tool=$impute_exec_path
  if ! $tool --help >/dev/null; then
    echo 'Impute5 is not found' >&2
    exit 1
  fi
}

load_shapeit() {
  tool=$shapeit_exec_path
  if ! $tool --help >/dev/null; then
    echo 'Shapeit is not found' >&2
    exit 1
  fi
}

if ! bcftools --help >/dev/null; then
  echo 'bcftools is not found' >&2
  exit 1
fi

num_threads=$(echo -e "$(($(nproc) / 3))\n1" | sort -n | tail -1)

usage() {
  echo "Usage: $0
-input_dir|-i <path> (required)
-file_name|-f <name> (required)
-output_dir|-o <path> (required)
-ref_panel|-r <path> (optional except imputing)
-genetic_map|-g <path> (required except minimac)
"
  if [ "$type" == "imputing" ]; then
    echo "Required for imputing (choose one):
    -phasing_tool|-p <tool>
    -phased_data|-pd <path>"
  fi
  echo "-num_threads|-n <number> (optional, default: $num_threads)
-regions <range>|-c (optional/required in some cases)
-extra_params|-e <params> (optional)
-silent (optional for run without print)
-log (optional for enable log)
-log_file <path> (optional for specify log file)"
}

parser() {
  if [[ "$#" -eq 0 ]]; then
    usage
    exit 0
  fi
  while [[ "$#" -gt 0 ]]; do
    case $1 in
    -input_dir | -i)
      input_dir="$2"
      shift
      ;;
    -file_name | -f)
      file_name="$2"
      shift
      ;;
    -output_dir | -o)
      output_dir="$2"
      shift
      ;;
    -ref_panel | -r)
      ref_panel="$2"
      shift
      ;;
    -genetic_map | -g)
      genetic_map="$2"
      shift
      ;;
    -num_threads | -n)
      num_threads="$2"
      shift
      ;;
    -regions | -c)
      regions="$2"
      shift
      ;;
    -extra_params | -e)
      extra_params="$2"
      shift
      ;;
    -phasing_tool | -p)
      phasing_tool="$2"
      shift
      ;;
    -phased_data | -pd)
      phased_data="$2"
      shift
      ;;
    -log)
      enable_log=0
      ;;
    -silent)
      enable_silent=0
      ;;
    -log_file)
      log="$2"
      shift
      ;;
    -help | -h)
      usage
      exit 0
      ;;
    *) ;;
    esac
    shift
  done
  if [ -z "$input_dir" ] || [ -z "$file_name" ] || [ -z "$output_dir" ]; then
    usage >&2
    exit 1
  fi
  if [ "$type" == "imputing" ]; then
    if [ -z "$phasing_tool" ] || [ -z "$ref_panel" ]; then
      usage >&2
      exit 1
    fi
    imputing_without_map=("minimac")
    if [ -z "$genetic_map" ] && [[ ! ${imputing_without_map[*]} =~ $toolname ]]; then
      usage >&2
      exit 1
    fi
    if [ ! -f "$phased_data" ]; then
      case $phasing_tool in
      beagle | eagle)
        phased_data="${output_dir}/output/phasing/${phasing_tool}/${file_name}.phased.vcf.gz"
        if [ ! -f "$phased_data" ]; then
          echo "Data doesn't exist. Please run phasing with $phasing_tool first" >&2
          exit 1
        fi
        ;;
      shapeit)
        phased_data="${output_dir}/output/phasing/shapeit/${file_name}.phased.vcf.gz"
        if [ ! -f "$phased_data" ]; then
          if [ -f "${output_dir}/output/phasing/shapeit/${file_name}.phased.bcf" ]; then
            (
              cd "${output_dir}/output/phasing/shapeit"
              bcftools convert -O z -o ${file_name}.phased.vcf.gz ${file_name}.phased.bcf
            )
          else
            echo "Data doesn't exist. Please run phasing with shapeit first" >&2
            exit 1
          fi
        fi
        ;;

      *)
        echo "Phasing tool not supported" >&2
        exit 1
        ;;
      esac
    fi
  fi

  output=${output_dir}/output/$type/$toolname
  mkdir -p "${output}"
  if [ -z "$log" ]; then
    log="${output}/${file_name}.log"
  fi

  case ${type}-${toolname} in
  phasing-beagle)
    params_final="gt=${input_dir}/${file_name} map=${genetic_map} out=${output}/${file_name}.phased impute=false nthreads=${num_threads}"
    if [ -z "$ref_panel" ]; then
      params_final="ref=${ref_panel} ${params_final}"
    fi
    ;;
  phasing-eagle)
    params_final="--vcfTarget ${input_dir}/${file_name} --geneticMapFile ${genetic_map}"
    if [ -z "$ref_panel" ]; then
      params_final="--vcfRef ${ref_panel} ${params_final}"
    fi
    if [ -z "$region" ]; then
      params_final="--chrom $region ${params_final}"
    fi
    params_final="${params_final} --outPrefix=${output}/${file_name}.phased --numThreads ${num_threads}"
    ;;
  phasing-shapeit)
    params_final="--input ${input_dir}/${file_name} --map ${genetic_map} --region $region"
    if [ -z "$ref_panel" ]; then
      params_final="--reference ${ref_panel} ${params_final}"
    fi
    params_final="${params_final} --outPrefix=${output}/${file_name}.phased.bcf --thread ${num_threads}"
    ;;
  imputing-beagle)
    params_final="gt=${phased_data} ref=${ref_panel} map=${genetic_map} out=${output}/${file_name}.imputed gp=true ap=true nthreads=${num_threads}"
    ;;
  imputing-impute)
    params_final="--h ${ref_panel} --m ${genetic_map} --g ${phased_data} --r ${region} --o ${output}/${file_name}.imputed.vcf.gz --buffer-region ${region}"
    ;;
  imputing-minimac)
    params_final="${ref_panel} ${phased_data} -o ${output}/${file_name}.imputed.vcf.gz --threads ${num_threads} -f GT"
    ;;
  *) ;;
  esac
  params_final="${params_final} ${extra_params}"
}

check_supported() {
  toolname=$1
  type=$2
  supporting_tools=("phasing-beagle" "phasing-eagle" "phasing-shapeit" "imputing-minimac" "imputing-impute" "imputing-beagle")
  if [[ ! ${supporting_tools[*]} =~ ${type}-${toolname} ]]; then
    echo "Tool not supported" >&2
    exit 1
  fi
  # shellcheck disable=SC2086
  load_$toolname
}

run_normal() {
  params="$*"
  # shellcheck disable=SC2086
  parser $toolname $type $params
  echo "${type} by ${toolname} with the following parameters:
  Input directory: $input_dir
  Prefix name: $file_name
  Output directory: $output_dir
  Log file: $log
  Reference panel: $ref_panel
  Genetic map: $genetic_map"
  if [ "$type" == "imputing" ]; then
    echo "Phasing tool: $phasing_tool
  Phased data: $phased_data"
  fi
  echo "Number of threads: $num_threads
  Regions: $regions
  Extra params: $extra_params
  "
  echo "${toolname} ${params_final}"
  # shellcheck disable=SC2086
  /usr/bin/time -f "Run in %E, with %M Kbytes of memory" $tool $params_final
}

run_silent() {
  params="$*"
  # shellcheck disable=SC2086
  parser $toolname $type $params
  # shellcheck disable=SC2086
  $tool ${params_final}
}

run() {
  params="$*"
  # shellcheck disable=SC2086
  parser $toolname $type $params
  if [ "$enable_log" ] && [ "$enable_silent" ]; then
    run >>"${log}" 2>&1
  elif [ ! "$enable_log" ] && [ "$enable_silent" ]; then
    run_silent
  elif [ "$enable_log" ] && [ ! "$enable_silent" ]; then
    run |& tee -a "${log}"
  elif [ ! "$enable_log" ] && [ ! "$enable_silent" ]; then
    run
  fi
}
