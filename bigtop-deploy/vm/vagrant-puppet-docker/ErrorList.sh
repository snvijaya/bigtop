#set -x
INPUTFILE=$1
OUTPUTFILE=$2
rm -f $OUTPUTFILE
while IFS='' read -r line || [ -n "$line" ]; do
       err=$(echo $line | grep -oE "err:[a-zA-Z0-9\(\)\.]+")
       TraceIdAndPath=$(echo $line | grep -oE "sReqId:(.*),")
       echo $err,$TraceIdAndPath >> $OUTPUTFILE
done < $INPUTFILE

