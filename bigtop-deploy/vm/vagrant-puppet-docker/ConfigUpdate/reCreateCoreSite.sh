#set -x
## ARGUMENT 1: CORE SITE FILE NAME WITH PATH
## ARGUMENT 2: ADL CONFIG FILE WITH PATH
## ARGUMENT 3: OUTPUT FILE WITH PATH

PATH_TO_CORE_SITE=$1
PATH_TO_ADL_CONFIG=$2
FILE_TO_CREATE=$3
TMPFile="$FILE_TO_CREATE.tmp"
CONTAINER_ROOT_NAME=${4-"tmpRoot"}

echo "reCreat 1"
echo "<configuration>" > $TMPFile
echo "reCreat 2"
sudo xmlstarlet sel -t -c "configuration/property" $1 >> $TMPFile
echo "reCreat 3"
sudo xmlstarlet sel -t -c "configuration/property" $2 >> $TMPFile
echo "reCreat 4"
echo "</configuration>" >> $TMPFile
echo "abc"
head $TMPFile
sudo sed 's/<property>/\n&/g' $TMPFile > $FILE_TO_CREATE
echo "def"
head $FILE_TO_CREATE
sudo xmlstarlet fo -R -t $FILE_TO_CREATE > $TMPFile
echo "ghi"
head $FILE_TO_CREATE
head $TMPFile
mv $TMPFile $FILE_TO_CREATE
head $FILE_TO_CREATE
sed -ie "s/CLUSTER_ROOT_NAME/$4/g" $FILE_TO_CREATE
