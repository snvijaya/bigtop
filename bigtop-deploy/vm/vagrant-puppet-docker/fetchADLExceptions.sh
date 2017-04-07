set -x
WORKSPACE=$1
FILE_TO_CREATE=${2-"ADL_Exceptions.txt"}

rm -f $WORKSPACE/$FILE_TO_CREATE

grep "HTTPRequest,F" $WORKSPACE/output.txt > $WORKSPACE/failed_request.txt.tmp
grep -v 'FileNotFoundException' $WORKSPACE/failed_request.txt.tmp > $WORKSPACE/failed_request.txt
./ErrorList.sh $WORKSPACE/failed_request.txt $WORKSPACE/Failed_Requests.csv
rm -rf $WORKSPACE/failed_request.txt.tmp $WORKSPACE/failed_request.txt
cat $WORKSPACE/Failed_Requests.csv


