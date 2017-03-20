set -x
## ARGUMENT 1: DOCKER CONTAINER ID
## ARGUMENT 2: CORE-SITE.XML FILE TO COPY
## ARGUMENT 3: CORE-SITE.XML COPY DESTINATION.
DOCKER_CONTAINER_ID=$1
HOST_NAME="$2.docker"
HDFS_SITE_FILE=${3-"/etc/hadoop/conf/hdfs-site.xml"}

sudo docker exec -i $DOCKER_CONTAINER_ID bash -lc "ls /etc/hadoop/conf"
sudo docker exec -i $DOCKER_CONTAINER_ID bash -lc "sudo sed -i '/ADLSETUP/ d' $HDFS_SITE_FILE"
sudo docker exec -i $DOCKER_CONTAINER_ID bash -lc "sed -i \"s/DOCKER_HOST/$HOST_NAME/g\" $HDFS_SITE_FILE"
sudo docker exec -i $DOCKER_CONTAINER_ID bash -lc "cat $HDFS_SITE_FILE"

