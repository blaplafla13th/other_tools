#!/bin/bash

pushd "$(dirname "$0")"
source check_requirement.sh
check_minimac
source params_parser.sh
popd
params="$*"
parser_imputing "minimac" $params
params_final="${ref_panel} ${phased_data} --map ${genetic_map} -o ${output}/${file_name}.imputed.vcf.gz --threads ${num_threads} -f GT"
(
echo "Imputing by Minimac4:"
echo "minimac ${params_final} ${extra_params}"
measure minimac "${params_final} ${extra_params}"
) |& tee -a "${log}"