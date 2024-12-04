#!/bin/bash

check_beagle() {
  if ! java -version 2>&1 | grep 1.8 > /dev/null; then
   echo 'Java 1.8 is required'
   exit 1
  fi
  unset beagle
  beagle_path=$(readlink -f bin/beagle.29Oct24.c8e.jar)
  beagle() {
    java -jar "$beagle_path" "$@"
  }
  if ! beagle > /dev/null; then
    echo 'Beagle is not found'
    exit 1
  fi
}

check_eagle() {
  unset eagle
  eagle_path=$(readlink -f bin/eagle_v2.4.1)
  eagle(){
    "$eagle_path" "$@"
  }
  if ! eagle --help > /dev/null; then
    echo 'Eagle is not found'
    exit 1
  fi
}

check_minimac() {
  unset minimac
  minimac_path=$(readlink -f bin/minimac4.1.6)
  minimac(){
    "$minimac_path" "$@"
  }
  if ! minimac --help > /dev/null; then
    echo 'Minimac is not found'
    exit 1
  fi
}

check_impute() {
  unset impute
  impute_path=$(readlink -f bin/impute5_v1.2.0)
  impute(){
    "$impute_path" "$@"
  }
  if ! impute --help > /dev/null; then
    echo 'Impute5 is not found'
    exit 1
  fi
}

check_shapeit(){
  unset shapeit
  shapeit_path=$(readlink -f bin/shapeit_phase_common_staticv5.1.1)
  shapeit(){
    "$shapeit_path" "$@"
  }
  if ! shapeit --help > /dev/null; then
    echo 'Shapeit is not found'
    exit 1
  fi
}

alias measure='/usr/bin/time -f "Run in %E, with %M Kbytes of memory"'
if ! bcftools --help > /dev/null; then
  echo 'bcftools is not found'
  exit 1
fi