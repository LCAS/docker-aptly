#!/bin/bash

set -e -x

read -r -d '' COMMAND << EOM
    aptly mirror update nvidia_cuda_2204_x86_64
    aptly snapshot create nvidia_cuda_2204_x86_64_$(date +%Y%m%d%H%M) from mirror nvidia_cuda_2204_x86_64
    aptly publish snapshot nvidia_cuda_2204_x86_64_$(date +%Y%m%d%H%M)

EOM

docker compose exec aptly bash -x -e -c "echo \"$COMMAND\""
