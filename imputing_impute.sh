#!/bin/bash

pushd "$(dirname "$0")"
source check_requirement.sh
check_impute
source params_parser.sh
popd
params="$*"
parser_imputing "impute" $params
params_final="--h ${ref_panel} --m ${genetic_map} --g ${phased_data} --r ${region} --o ${output}/${file_name}.imputed.vcf.gz --buffer-region ${region}"
(
echo "Imputing by Impute5:"
echo "impute ${params_final} ${extra_params}"
# Impute by beagle
measure impute ${params_final} ${extra_params}
) |& tee -a "${log}"