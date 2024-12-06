#!/bin/bash

pushd "$(dirname "$0")"
source launch_function.sh
check_supported "beagle" "phasing"
popd
run_with_log "$@"