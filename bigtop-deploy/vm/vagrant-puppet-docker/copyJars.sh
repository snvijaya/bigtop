set -x
## ARGUMENT 1: CONTAINER ID
## ARGUMENT 2: PATH TO SDK JAR
## ARGUMENT 3: PATH TO DRIVER JAR

CONTAINER_ID=${1-"80133d746b6d"}
#SDK_JAR_PATH=${2-"/var/lib/jenkins/workspace/ADLSDK/target/"}
#DRIVER_JAR_PATH=${3-"/var/lib/jenkins/workspace/ADLDriver/target/"}
SDK_JAR_PATH=${2-"/var/lib/jenkins/workspace/adlmr/SDK/target/"}
DRIVER_JAR_PATH=${3-"/var/lib/jenkins/workspace/adlmr/Driver/target/"}

SDK_JAR_FILE_PATTERN="$SDK_JAR_PATH/*azure-data-lake-store*.jar"
DRIVER_JAR_FILE_PATTERN="$DRIVER_JAR_PATH/*hadoop-azure-datalake*.jar"

copyJar() {
    filePattern=$1
    echo Called copyJar from folder $filePattern
    for f in $filePattern; do
       echo Check if $f needs to be copied
       file_to_copy=true
       if [ "$f" = *"sources"* ] || [ "$f" = *"tests"* ] || [ "$f" = *"javadoc"* ]; then
       	 file_to_copy=false
	 echo Excluding file $f from copy to docker
       fi
     done
     if [ "$file_to_copy" = "true" ]; then
        echo Copying file $f to Container $CONTAINER_ID over path /usr/lib/hadoop/lib/
        docker cp $f $CONTAINER_ID:/usr/lib/hadoop/lib/
     fi
}

## Fetch com.fasterxml.jackson.core.jar 
if [ ! -f com.fasterxml.jackson.core.jar ]; then
wget http://www.java2s.com/Code/JarDownload/com.fasterxml/com.fasterxml.jackson.core.jar.zip -P ~/
unzip ~/com.fasterxml.jackson.core.jar.zip 
chmod 777 com.fasterxml.jackson.core.jar
rm -f ~/com.fasterxml.jackson.core.jar.zip
fi
#docker cp com.fasterxml.jackson.core.jar $CONTAINER_ID:/usr/lib/hadoop/lib/


filePattern=$SDK_JAR_FILE_PATTERN
copyJar $filePattern
filePattern=$DRIVER_JAR_FILE_PATTERN
copyJar $filePattern


