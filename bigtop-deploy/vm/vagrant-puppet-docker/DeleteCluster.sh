set -x

# INPUTS
JOB_NAME=$1
CONFIG_DIR=$2

echo ***SN: JOB = $JOB_NAME

pwd
cd $CONFIG_DIR
pwd
CONTAINER_ID=$(docker ps -a | grep $JOB_NAME | awk '{print $1}')
echo ***SN: DELETE CLUSTER
sudo docker exec -i $CONTAINER_ID bash -lc "/vagrant/deleteClusterAdlRoot.sh"
# clear the container and config
sudo docker stop $CONTAINER_ID
sudo docker rm $CONTAINER_ID
vagrantconfigfile="vagrantconfig$JOB_NAME.yaml"
sudo rm -f $vagrantconfigfile
cd -

