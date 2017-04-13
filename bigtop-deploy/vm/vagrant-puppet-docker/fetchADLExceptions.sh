set -x
WORKSPACE=$1
FILE_TO_CREATE=${2-"ADL_Exceptions.txt"}

rm -f $WORKSPACE/$FILE_TO_CREATE


crt $WORKSPACE/Failed_Requests.csv
RKSPACE/failed_request.txt.tmp
grep -v 'FileNotFoundException' $WORKSPACE/failed_request.txt.tmp > $WORKSPACE/failed_request.txt
cat $WORKSPACE/failed_request.txt
./ErrorList.sh $WORKSPACE/failed_request.txt $WORKSPACE/Failed_Requests.csv
rm -rf $WORKSPACE/failed_request.txt.tmp $WORKSPACE/failed_request.txt
cat $WORKSPACE/Failed_Requests.csv
echo Status,TraceId,Path | cat - $WORKSPACE/Failed_Requests.csv  > $WORKSPACE/Failed_Requests_With_Header.csv
< $WORKSPACE/Failed_Requests_With_Header.csv csvsort -rc Status | csvlook > $WORKSPACE/Failed_Requests
cat $WORKSPACE/Failed_Requests


