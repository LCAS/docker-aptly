#!/bin/bash

set -e -x

docker exec aptly bash -x -e -c "aptly graph -output=/opt/aptly/public/aptly_graph.png"
docker exec aptly bash -x -e -c "aptly publish list"
