#set -x
## ARGUMENT 1: CORE SITE FILE NAME WITH PATH
## ARGUMENT 2: ADL CONFIG FILE WITH PATH
## ARGUMENT 3: OUTPUT FILE WITH PATH

PATH_TO_CORE_SITE=$1
PATH_TO_ADL_CONFIG=$2
FILE_TO_CREATE=$3
TMPFile="$FILE_TO_CREATE.tmp"
CONTAINER_ROOT_NAME=${4-"tmpRoot"}

cat $PATH_TO_CORE_SITE
cat $PATH_TO_ADL_CONFIG
echo "<configuration>" > $TMPFile
sudo xmlstarlet sel -t -c "configuration/property" $1 >> $TMPFile
sudo xmlstarlet sel -t -c "configuration/property" $2 >> $TMPFile
echo "</configuration>" >> $TMPFile
sudo sed 's/<property>/\n&/g' $TMPFile > $FILE_TO_CREATE
sudo xmlstarlet fo -R -t $FILE_TO_CREATE > $TMPFile
mv $TMPFile $FILE_TO_CREATE
sed -ie "s/DOCKER_HOST/$4/g" $FILE_TO_CREATE
cat $FILE_TO_CREATE
