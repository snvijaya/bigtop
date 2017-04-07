#set -x
PATH_TO_TEST_OUTPUT=$1
FILE_TO_CREATE=$2
TMPFile="$FILE_TO_CREATE.tmp"

rm -f $FILE_TO_CREATE

for file in $PATH_TO_TEST_OUTPUT/*.xml; do
  fileName=${file##*/}
  cat $PATH_TO_TEST_OUTPUT/$fileName | sudo xmlstarlet sel -t -c "testsuite/testcase" >> $FILE_TO_CREATE
done

sudo sed -i '1s/^/<?xml version="1.0" encoding="UTF-8"?> \n <testsuite> \n/' $FILE_TO_CREATE
sudo sed -i -e "\$a</testsuite>" $FILE_TO_CREATE
cat $FILE_TO_CREATE

