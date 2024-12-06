#!/bin/bash

pushd "$(dirname "$0")"
source launch_function.sh
check_supported "shapeit" "phasing"
popd
run "$@"