set -x
DIR=$1
CONSOLEFILE="$1/output.txt"
TMPFILE1="$1/tmp1"
TMPFILE2="$1/tmp2"
XMLFILE="$1/result.xml"

sudo grep -e STARTED -e FAILED $CONSOLEFILE > $TMPFILE1
#sudo grep TestEventLogger $TMPFILE1 > $TMPFILE2 
sudo grep ">" $TMPFILE1 > $TMPFILE2
#cat step3

> $TMPFILE1 

while IFS='' read -r line || [ -n "$line" ]; do
        SUBSTR=$(echo $line| cut -d'>' -f 2)
        if echo "$SUBSTR" | grep -q "test "; then
		testfullname=$(echo $line| awk '{print $1;}')
	#	testname=$(echo $testfullname| awk -F. '{print $NF}')
	        testname=$(echo ${testfullname##*.})
	        state=$(echo $line| awk '{print $(NF);}') 
	        SUBSTR="$testname $state"
        fi
        echo $SUBSTR >> $TMPFILE1
done < $TMPFILE2

> $TMPFILE2

while IFS='' read -r line || [ -n "$line" ]; do
        test=$(echo $line | awk '{print $1;}')
        occurence=$(grep -c $test $TMPFILE2)
# Java result will habe a line for test started and nothing if there is a pass
        if [ "$occurence" -lt "2" ]; then
            if echo "$line" | grep -q "FAILED"; then
                 echo "<testcase name=\"$test\" classname=\"ADLSuite\" result=\"Failure\" success=\"False\" >" >> $TMPFILE2
                 echo "          <failure> Check the output.txt file and search with test name </failure>" >> $TMPFILE2
                 echo "</testcase>" >> $TMPFILE2
            else 
           	echo "<testcase name=\"$test\" classname=\"ADLSuite\" result=\"Success\" success=\"True\" />" >> $TMPFILE2
	    fi
        fi

        if [ $occurence -gt 1 ]; then
	   if echo "$line" | grep -q "FAILED"; then
                echo "<testcase name=\"$test\" classname=\"ADLSuite\" result=\"Failure\" success=\"False\" >" >> $TMPFILE2 
		echo "		<failure> Check the output.txt file and search with test name </failure>" >> $TMPFILE2
		echo "</testcase>" >> $TMPFILE2
            fi

           if echo "$line" | grep -q "PASSED"; then
		echo "<testcase name=\"$test\" classname=\"ADLSuite\" result=\"Success\" success=\"True\" />" >> $TMPFILE2
           fi

        fi
done < $TMPFILE1

sudo sed -i '1s/^/<?xml version="1.0" encoding="UTF-8"?> \n <testsuite> \n/' $TMPFILE2 
sudo sed -i -e "\$a</testsuite>" $TMPFILE2

cat $TMPFILE2 
cp $TMPFILE2 $XMLFILE 
