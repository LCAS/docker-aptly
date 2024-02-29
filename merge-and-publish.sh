#!/bin/bash

set -x -e

TIMESTAMP=`date +%Y%m%d%H%M`

MIRRORS="nvidia_cuda_2204_x86_64"
REPOS="lcas_ros"
DISTRO=jammy

ALL_SNAPSHOTS=""
for MIRROR in $MIRRORS; do
    aptly mirror update "$MIRROR"
    aptly snapshot create "${MIRROR}_${TIMESTAMP}" from mirror $MIRROR
    ALL_SNAPSHOTS="$ALL_SNAPSHOTS ${MIRROR}_${TIMESTAMP}"
done

for REPO in $REPOS; do
    aptly snapshot create "${REPO}_${TIMESTAMP}" from repo $REPO
    ALL_SNAPSHOTS="$ALL_SNAPSHOTS ${REPO}_${TIMESTAMP}"
done

MERGED_SNAPSHOT="release_${TIMESTAMP}"

aptly snapshot merge $MERGED_SNAPSHOT $ALL_SNAPSHOTS
aptly publish snapshot -architectures amd64,arm64 -distribution ${DISTRO} $MERGED_SNAPSHOT
