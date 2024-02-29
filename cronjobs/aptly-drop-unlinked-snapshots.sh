#!/bin/bash

set -x

docker exec aptly bash -x -e -c "aptly snapshot list --raw | xargs -n 1 -- aptly snapshot drop"
sleep 1
docker exec aptly bash -x -e -c "aptly snapshot list --raw | xargs -n 1 -- aptly snapshot drop"
sleep 1
docker exec aptly bash -x -e -c "aptly graph -output=/opt/aptly/public/aptly_graph.png"
