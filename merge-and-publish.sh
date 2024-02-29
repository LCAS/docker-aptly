#!/bin/bash

# run required merge and updates to make a new release

TIMESTAMP=`date +%Y%m%d%H%M`
REPO_SNAPSHOT="lcas_${TIMESTAMP}"
NVIDIA2204_SNAPSHOT="nvidia_cuda_2204_x86_64_${TIMESTAMP}"
MERGED_SNAPSHOT="merged_${TIMESTAMP}"

aptly snapshot create $REPO_SNAPSHOT from repo lcas_ros
aptly snapshot create $NVIDIA2204_SNAPSHOT from mirror nvidia_cuda_2204_x86_64
aptly snapshot merge $MERGED_SNAPSHOT $REPO_SNAPSHOT $NVIDIA2204_SNAPSHOT
aptly publish snapshot -distribution jammy $MERGED_SNAPSHOT
