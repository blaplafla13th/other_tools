#!/bin/bash

pushd "$(dirname "$0")"
source check_requirement.sh
check_beagle
source params_parser.sh
popd
params="$*"
parser_imputing "beagle" $params
params_final="gt=${phased_data} ref=${ref_panel} map=${genetic_map} out=${output}/${file_name}.imputed gp=true ap=true nthreads=${num_threads}"
(
echo "Imputing by Beagle:"
echo "beagle ${params_final} ${extra_params}"
measure beagle "${params_final} ${extra_params}"
) |& tee -a "${log}"