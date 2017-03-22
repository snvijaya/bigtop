set -x
## ARGUMENT 1: DOCKER CONTAINER ID
## ARGUMENT 2: CORE-SITE.XML FILE TO COPY
## ARGUMENT 3: CORE-SITE.XML COPY DESTINATION. 
DOCKER_CONTAINER_ID=$1
CORE_SITE_FILE_TO_COPY=$2
CORE_SITE_DESTINATION_FOLDER=${3-"/etc/hadoop/conf/"}

sudo docker exec -i $DOCKER_CONTAINER_ID bash -lc "ls /etc/hadoop/conf"
sudo docker cp $CORE_SITE_FILE_TO_COPY $DOCKER_CONTAINER_ID:$CORE_SITE_DESTINATION_FOLDER

