pushd "$(dirname "$0")"
source launch_function.sh
popd
usage() {
  echo "Usage: $0
  -input_dir|-i <path> (required)
  -file_name|-f <name> (required)
  -output_dir|-o <path> (required)
  -ref_panel|-r <path> (required)
  -ref_panel_msav|-rv <path> (optional, if dont exist, it will be created from ref_panel)
  -genetic_map_beagle|-gb <path> (required)
  -genetic_map_eagle|-ge <path> (required)
  -genetic_map_shapeit|-gs <path> (required)
  -regions <range>|-c (required)
  -num_threads|-n <number> (optional, default: $num_threads)"
}
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
  -ref_panel_msav | -rv)
    ref_panel_msav="$2"
    shift
    ;;
  -genetic_map_beagle | -gb)
    genetic_map_beagle="$2"
    shift
    ;;
  -genetic_map_eagle | -ge)
    genetic_map_eagle="$2"
    shift
    ;;
  -genetic_map_shapeit | -gs)
    genetic_map_shapeit="$2"
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
  -help | -h)
    usage
    exit 0
    ;;
  *) ;;
  esac
  shift
done
if [ -z "$input_dir" ] || [ -z "$file_name" ] || [ -z "$output_dir" ] || [ -z "$ref_panel" ] || [ -z "$genetic_map_beagle" ] || [ -z "$genetic_map_eagle" ] || [ -z "$genetic_map_shapeit" ] || [ -z "$regions" ]; then
  usage
  exit 1
fi

if [ -z "$ref_panel_msav" ]; then
  ref_panel_msav="$ref_panel.msav"
  if [ ! -f "$ref_panel_msav" ]; then
    pushd $(dirname "$ref_panel")
    load_minimac
    $tool --compress-reference $ref_panel >$ref_panel_msav
    popd
  fi
fi

params_phasing="-input_dir $input_dir -file_name $file_name -regions $regions -num_threads $num_threads"
params_imputing="$params_phasing -ref_panel $ref_panel"
# no-ref
params_phasing_noref="$params_phasing -output_dir $output_dir/noref"
params_imputing_noref="$params_imputing -output_dir $output_dir/noref"
check_supported "beagle" "phasing"
run_normal $params_phasing_noref -genetic_map $genetic_map_beagle
check_supported "eagle" "phasing"
run_normal $params_phasing_noref -genetic_map $genetic_map_eagle
check_supported "shapeit" "phasing"
run_normal $params_phasing_noref -genetic_map $genetic_map_shapeit
for phasing_tool_current in beagle eagle shapeit; do
  check_supported "beagle" "imputing"
  run_normal $params_imputing_noref -phasing_tool $phasing_tool_current -genetic_map $genetic_map_beagle
  check_supported "impute" "imputing"
  run_normal $params_imputing_noref -phasing_tool $phasing_tool_current -genetic_map $genetic_map_shapeit
  check_supported "minimac" "imputing"
  run_normal $params_phasing_noref -phasing_tool $phasing_tool_current -ref_panel $ref_panel_msav
done

# ref
params_phasing_ref="$params_imputing -output_dir $output_dir/ref"
check_supported "beagle" "phasing"
run_normal $params_phasing_ref -genetic_map $genetic_map_beagle
check_supported "eagle" "phasing"
run_normal $params_phasing_ref -genetic_map $genetic_map_eagle
check_supported "shapeit" "phasing"
run_normal $params_phasing_ref -genetic_map $genetic_map_shapeit
for phasing_tool_current in beagle eagle shapeit; do
  check_supported "beagle" "imputing"
  run_with_log $params_phasing_ref -phasing_tool $phasing_tool_current -genetic_map $genetic_map_beagle
  check_supported "impute" "imputing"
  run_with_log $params_phasing_ref -phasing_tool $phasing_tool_current -genetic_map $genetic_map_shapeit
  check_supported "minimac" "imputing"
  run_with_log $params_phasing_ref -phasing_tool $phasing_tool_current -ref_panel $ref_panel_msav
done
