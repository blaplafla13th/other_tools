#!/bin/bash

pushd "$(dirname "$0")"
source launch_function.sh
check_supported "beagle" "imputing"
popd
run_with_log "$@"