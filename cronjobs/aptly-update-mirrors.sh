#!/bin/bash

set -e -x

# This script updates the mirrors for a specified distribution.
# Usage: ./aptly-update-mirrors.sh [DISTRO]
# Arguments:
#   DISTRO: (Optional) The name of the distribution to update mirrors for.
#           If not provided, the script will use the default distribution (jammy).
if [ -n "$1" ]; then
    DISTRO="$1"
else
    DISTRO=${DISTRO:-jammy}
fi

if [ -n "$2" ]; then
    REPOS="$2"
else
    REPOS=${REPOS:-lcas_ros}
fi

echo "running update for distribution $DISTRO"

TIMESTAMP=`date +%Y%m%d%H%M`

#MIRRORS="nvidia_cuda_2204_x86_64 osrf_gazebo_jammy"
MIRRORS="`docker exec aptly bash -x -e -c 'aptly mirror list --raw' | grep -v '^eol_' | grep _${DISTRO}`"
echo "mirrors to update: $MIRRORS"

REPOS="${REPOS}_${DISTRO}"

echo "repo to update: $REPOS"

PUBLISH_PREFIX=lcas

# created mirror with 
# aptly mirror create nvidia_cuda_2204_x86_64 https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ ./ 

# create a initial publish from snapshot:
# aptly publish snapshot  -architectures amd64,arm64 -component lcas -distribution jammy release_202402291420 lcas

ALL_SNAPSHOTS=""
for MIRROR in $MIRRORS; do
    docker exec aptly bash -x -e -c "aptly mirror update '$MIRROR'"
    docker exec aptly bash -x -e -c "aptly snapshot create '${MIRROR}_${TIMESTAMP}' from mirror $MIRROR"
    ALL_SNAPSHOTS="$ALL_SNAPSHOTS ${MIRROR}_${TIMESTAMP}"
done

MERGED_MIRROR_SNAPSHOT="mirrors_${DISTRO}_${TIMESTAMP}"

docker exec aptly bash -x -e -c "aptly snapshot merge $MERGED_MIRROR_SNAPSHOT $ALL_SNAPSHOTS"

# for REPO in $REPOS; do
#     docker exec aptly bash -x -e -c "aptly snapshot create '${REPO}_${TIMESTAMP}' from repo $REPO"
#     ALL_SNAPSHOTS="$ALL_SNAPSHOTS ${REPO}_${TIMESTAMP}"
# done

# find latest repo snapshot
LAST_REPO_SNAPSHOT=`docker exec aptly bash -x -e -c "aptly snapshot list --raw" | grep "^${REPOS}" | sort | tail -n1`
ALL_SNAPSHOTS="$MERGED_MIRROR_SNAPSHOT $LAST_REPO_SNAPSHOT"

RELEASE_SNAPSHOT="release_${DISTRO}_${TIMESTAMP}"


# create a new merged snapshot
docker exec aptly bash -x -e -c "aptly snapshot merge $RELEASE_SNAPSHOT $ALL_SNAPSHOTS"

# switch the publication to the new merged snapshot
docker exec aptly bash -x -e -c "aptly publish switch -batch ${DISTRO} ${PUBLISH_PREFIX} ${RELEASE_SNAPSHOT}"

# drop no longer used snapshots of the merged snapshot
docker exec aptly bash -x -e -c "aptly snapshot list --raw | grep "^release_" | xargs -n 1 -- aptly snapshot drop" || true
docker exec aptly bash -x -e -c "aptly snapshot list --raw | grep "^mirrors_" | xargs -n 1 -- aptly snapshot drop" || true

# drop no longer used snapshots of the mirrors
for MIRROR in $MIRRORS; do
    docker exec aptly bash -x -e -c "aptly snapshot list --raw | grep "^${MIRROR}_" | xargs -n 1 -- aptly snapshot drop" || true
done

# update the graph
docker exec aptly bash -x -e -c "aptly graph -output=/opt/aptly/public/aptly_graph.png"
