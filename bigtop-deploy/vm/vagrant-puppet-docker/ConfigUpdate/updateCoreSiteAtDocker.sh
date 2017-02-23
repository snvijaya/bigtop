PATH_TO_CORE_SITE=$1
PATH_TO_ADL_CONFIG=$2
DOCKER_CONTAINER_ID=$3
CORE_SITE_DESTINATION_FOLDER=${4-"/bigtop-home/bigtop-deploy/puppet/modules/hadoop/templates/"}

reCreateCoreSite $PATH_TO_CORE_SITE $PATH_TO_ADL_CONFIG core-site.xml

copyCoreSiteToDocker $DOCKER_CONTAINER_ID core-site.xml $CORE_SITE_DESTINATION_FOLDER/core-site.xml

sudo rm core-site.xml


