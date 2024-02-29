#!/bin/bash

set -e -x

TIMESTAMP=`date +%Y%m%d%H%M`

MIRRORS="nvidia_cuda_2204_x86_64 osrf_gazebo_jammy"
REPOS="lcas_ros"
DISTRO=jammy
PUBLISH_PREFIX=hurga

# created mirror with 
# aptly mirror create nvidia_cuda_2204_x86_64 https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ ./ 

# create a initial publish from snapshot:
# aptly publish snapshot  -architectures amd64,arm64 -distribution jammy release_202402291420 hurga

ALL_SNAPSHOTS=""
for MIRROR in $MIRRORS; do
    docker exec aptly bash -x -e -c "aptly mirror update '$MIRROR'"
    docker exec aptly bash -x -e -c "aptly snapshot create '${MIRROR}_${TIMESTAMP}' from mirror $MIRROR"
    ALL_SNAPSHOTS="$ALL_SNAPSHOTS ${MIRROR}_${TIMESTAMP}"
done

MERGED_MIRROR_SNAPSHOT="mirrors_${TIMESTAMP}"

docker exec aptly bash -x -e -c "aptly snapshot merge $MERGED_MIRROR_SNAPSHOT $ALL_SNAPSHOTS"

# for REPO in $REPOS; do
#     docker exec aptly bash -x -e -c "aptly snapshot create '${REPO}_${TIMESTAMP}' from repo $REPO"
#     ALL_SNAPSHOTS="$ALL_SNAPSHOTS ${REPO}_${TIMESTAMP}"
# done

# find latest repo snapshot
LAST_REPO_SNAPSHOT=`docker exec aptly bash -x -e -c "aptly snapshot list --raw" | grep "^${REPOS}" | sort | tail -n1`
ALL_SNAPSHOTS="$MERGED_MIRROR_SNAPSHOT $LAST_REPO_SNAPSHOT"

RELEASE_SNAPSHOT="release_${TIMESTAMP}"


# create a new merged snapshot
docker exec aptly bash -x -e -c "aptly snapshot merge $RELEASE_SNAPSHOT $ALL_SNAPSHOTS"

# switch the publication to the new merged snapshot
docker exec aptly bash -x -e -c "aptly publish switch ${DISTRO} ${PUBLISH_PREFIX} ${RELEASE_SNAPSHOT}"

# drop no longer used snapshots of the merged snapshot
docker exec aptly bash -x -e -c "aptly snapshot list --raw | grep "^release_" | xargs -n 1 -- aptly snapshot drop" || true
docker exec aptly bash -x -e -c "aptly snapshot list --raw | grep "^mirrors_" | xargs -n 1 -- aptly snapshot drop" || true

# drop no longer used snapshots of the mirrors
for MIRROR in $MIRRORS; do
    docker exec aptly bash -x -e -c "aptly snapshot list --raw | grep "^${MIRROR}_" | xargs -n 1 -- aptly snapshot drop" || true
done

# update the graph
docker exec aptly bash -x -e -c "aptly graph -output=/opt/aptly/public/aptly_graph.png"
