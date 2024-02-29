APTLY_API="https://lcas.lincoln.ac.uk/apt/api"
repo=lcas_ros
echo "Updating published repo..."

read -r -d '' DATA <<- EOM
{
    "Name": "TESTSNAP"
}
EOM

echo $VAR
# create snapshot
curl  -X POST -H 'Content-Type: application/json' --data "${DATA}" -u lcas:${APTLY_TOKEN} $APTLY_API/repos/lcas_ros/snapshots
