#!/bin/bash
ref_panel=''
num_threads=$(echo -e "$(($(nproc)/3))\n1" | sort -n | tail -1)
extra_params=''
parser_phasing(){
  toolname=$1
  shift
  usage() {
      echo "Usage: $0
      -input_dir|-i <path> (required)
      -file_name|-f <name> (required)
      -output_dir|-o <path> (required)
      -ref_panel|-r <path> (optional)
      -genetic_map|-g <path> (required)
      -num_threads|-n <number> (optional)
      -regions <range>|-c (optional/required in some cases)
      -extra_params|-e <params> (optional)"
  }
  if [[ "$#" -eq 0 ]]; then
      usage
      exit 0
  fi

  while [[ "$#" -gt 0 ]]; do
      case $1 in
          -input_dir|-i) input_dir="$2"; shift ;;
          -file_name|-f) file_name="$2"; shift ;;
          -output_dir|-o) output_dir="$2"; shift ;;
          -ref_panel|-r) ref_panel="$2"; shift ;;
          -genetic_map|-g) genetic_map="$2"; shift ;;
          -num_threads|-n) num_threads="$2"; shift ;;
          -regions|-c) regions="$2"; shift ;;
          -extra_params|-e) extra_params="$2"; shift ;;
          -help|-h|*) usage; exit 0 ;;
      esac
      shift
  done
  if [ -z "$input_dir" ] || [ -z "$file_name" ] || [ -z "$output_dir" ] || [ -z "$genetic_map" ]; then
      usage
      exit 1
  fi
  output=${output_dir}/output/phasing/$toolname
  mkdir -p ${output}
  log=$(readlink -f ${output}/${file_name}.log)
  echo "Running with the following parameters:
    Input directory: $input_dir
    Prefix name: $file_name
    Output directory: $output_dir
    Reference panel: $ref_panel
    Genetic map: $genetic_map
    Number of threads: $num_threads
    Regions: $regions
    Extra params: $extra_params
    Log file: $log" | tee -a ${log}
}

parser_imputing(){
  toolname=$1
  shift
  usage() {
      echo "Usage: $0
      -input_dir|-i <path> (required)
      -file_name|-f <name> (required)
      -output_dir|-o <path> (required)
      -ref_panel|-r <path> (optional)
      -genetic_map|-g <path> (required)
      -num_threads|-n <number> (optional)
      -regions|-c <range> (optional/required in some cases)
      -phasing_tool|-p <tool> (required)
      -extra_params|-e <params> (optional)"
  }
  if [[ "$#" -eq 0 ]]; then
      usage
      exit 0
  fi

  while [[ "$#" -gt 0 ]]; do
      case $1 in
          -input_dir|-i) input_dir="$2"; shift ;;
          -file_name|-f) file_name="$2"; shift ;;
          -output_dir|-o) output_dir="$2"; shift ;;
          -ref_panel|-r) ref_panel="$2"; shift ;;
          -genetic_map|-g) genetic_map="$2"; shift ;;
          -num_threads|-n) num_threads="$2"; shift ;;
          -regions|-v) regions="$2"; shift ;;
          -phasing_tool|-p) phasing_tool="$2"; shift ;;
          -extra_params|-e) extra_params="$2"; shift ;;
          -help|-h) usage; exit 0 ;;
      esac
      shift
  done
  if [ -z "$input_dir" ] || [ -z "$file_name" ] || [ -z "$output_dir" ] || [ -z "$genetic_map" ] || [ -z "$phasing_tool" ] || [ -z "$ref_panel" ];
  then
      usage
      exit 1
  fi
  case $phasing_tool in
    beagle|eagle|shapeit)
      phased_data="${output_dir}/output/phasing/${phasing_tool}/${file_name}.phased.vcf.gz"
      if [ ! -f "$phased_data" ]; then
        echo "Data doesn't exist. Please run phasing with $phasing_tool first"
        exit 1
      fi
      ;;
    *)
      echo "Phasing tool not supported"
      exit 1
      ;;
  esac
  output=${output_dir}/output/imputation/$toolname
  mkdir -p ${output}
  log=$(readlink -f ${output}/${file_name}.log)
  echo "Running with the following parameters:
    Input directory: $input_dir
    Prefix name: $file_name
    Output directory: $output_dir
    Reference panel: $ref_panel
    Genetic map: $genetic_map
    Number of threads: $num_threads
    Regions: $regions
    Phasing tool: $phasing_tool
    Phased data: $phased_data
    Extra params: $extra_params
    Log file: $log" | tee -a ${log}
}

