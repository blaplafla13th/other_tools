#!/bin/bash

pushd "$(dirname "$0")"
source check_requirement.sh
check_eagle
source params_parser.sh
popd
params="$*"
parser_phasing "shapeit" $params
params_final="--input ${input_dir}/${file_name} --map ${genetic_map} --region $region"
if [ -z "$ref_panel" ]; then
  params_final="--reference ${ref_panel} ${params_final}"
fi
params_final="${params_final} --outPrefix=${output}/${file_name}.phased.bcf --thread ${num_threads}"
(
echo "Phasing by Shapeit:"
echo "shapeit ${params_final} ${extra_params}"
measure shapeit ${params_final} ${extra_params}
) |& tee -a "${log}"
bcftools convert -O z -o ${output}/${file_name}.phased.vcf.gz ${output}/${file_name}.phased.bcf