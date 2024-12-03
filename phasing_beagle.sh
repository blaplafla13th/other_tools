#!/bin/bash

pushd "$(dirname "$0")"
source check_requirement.sh
check_beagle
source params_parser.sh
popd
params="$*"
parser_phasing "beagle" $params
params_final="gt=${input_dir}/${file_name} map=${genetic_map} out=${output}/${file_name}.phased impute=false nthreads=${num_threads}"
if [ -z "$ref_panel" ]; then
  params_final="ref=${ref_panel} ${params_final}"
fi
(
echo "Phasing by Beagle:"
echo "beagle ${params_final}"
measurebeagle ${params_final}
) |& tee -a "${log}"