#!/bin/bash

pushd "$(dirname "$0")"
source check_requirement.sh
check_eagle
source params_parser.sh
popd
params="$*"
parser_phasing "eagle" $params
params_final="--vcfTarget ${input_dir}/${file_name} --geneticMapFile ${genetic_map}"
if [ -z "$ref_panel" ]; then
  params_final="--vcfRef ${ref_panel} ${params_final}"
fi
if [ -z "$region" ]; then
  params_final="--chrom $region ${params_final}"
fi
params_final="${params_final} --outPrefix=${output}/${file_name}.phased --numThreads ${num_threads}"
(
echo "Phasing by Eagle:"
echo "eagle ${params_final}"
measure eagle ${params_final}
) |& tee -a "${log}"