#set -x
# PASS 8  ARGUMENTS
# 1 -> TEST COMPONENT DIRECTORY NAME IN DOCKER
# 2 -> {WORKSPACE}
# 3 -> {JOB_NAME}
# 4 -> {BUILD_NUMBER}
# 5 -> HOST VAGRANT SCRIPT DIR
# 6 -> PATH TO ADL CONFIG FILE
# 7 -> FLAG DESTROY DOCKER AT END
# 8 -> FLAG IF CLUSTER ALREADY EXISTS 

# INPUTS 
TESTDIR=$1
WORK_SPACE=$2
JOB_NAME=$3
BUILD_NUMBER=$4
CONFIG_DIR=$5
ADL_CONFIG_FILE_PATH=$6
DELETECLUSTER=${7-true}
CLUSTEREXISTS=${8-false}

COMPONENT=$TESTDIR

# ADL Jars - copied by plugin
echo "SN: Jars copied to workspace"
ls $WORK_SPACE/Driver/target/
ls $WORK_SPACE/SDK/target/

echo ***SN: CLUSTEREXISTS = $CLUSTEREXISTS

if [ "$CLUSTEREXISTS" = "false" ]; then
# Create vagrant docker
cd $CONFIG_DIR
sudo ./singleNodeHadoop.sh --create $JOB_NAME $ADL_CONFIG_FILE_PATH $COMPONENT
fi

# OUTPUT FILES
resultFile="result-$JOB_NAME-$BUILD_NUMBER.xml"
htmlReport="htmlReport-$JOB_NAME-$BUILD_NUMBER"

echo ***SN: WORKSPACE= $WORK_SPACE
echo ***SN: PWD = $PWD
echo ***SN: JOB = $JOB_NAME
echo ***SN: DELETE CLUSTER AT END = $DELETECLUSTER

#cd $WORK_SPACE

## BACKUP
#mkdir -p $WORK_SPACE/older_run_archive
## BACKUP RESULT XML
#if ls $WORK_SPACE/result* 1> /dev/null 2>&1; then
#	sudo mv result-* $WORK_SPACE/older_run_archive
#fi
## BACKUP HTML 	
#if ls htmlReport-* 1> /dev/null 2>&1; then
#	sudo mv -v $WORK_SPACE/htmlReport-* $WORK_SPACE/older_run_archive
#fi
pwd

# RUN TEST
cd $CONFIG_DIR
pwd
CONTAINER_ID=$(docker ps -a | grep $JOB_NAME | awk '{print $1}')
echo ***SN: CONTAINER USED FOR TESTING = $CONTAINER_ID ==> $(docker ps -a | grep $JOB_NAME | awk '{print $7}')

if [ "$CLUSTEREXISTS" = "false" ]; then
echo ***SN: Duplicate bigtop env so that tests can run
sudo docker exec -i $CONTAINER_ID bash -lc "sudo cp -r /bigtop-home/ /bigtop/"
sudo docker exec -i $CONTAINER_ID bash -lc "localedef -i en_US -f UTF-8 en_US.UTF-8"

echo ***SN: Enable gradle daemonfor subsequent runs to be faster
sudo docker exec -i $CONTAINER_ID bash -lc "touch ~/.gradle/gradle.properties && echo \"org.gradle.daemon=true\" >> ~/.gradle/gradle.properties"

echo ***SN: COPY ADL JARS
ls $WORK_SPACE | grep *.jar
sudo ./copyJars.sh $CONTAINER_ID "$WORK_SPACE/SDK/target/" "$WORK_SPACE/Driver/target/" 

echo ***SN: GET THE CLUSTER READY FOR CONTAINER SUPPORT
sudo docker exec -i $CONTAINER_ID bash -lc "ls /usr/lib/hadoop/lib/ | grep azure"
sudo docker exec -i $CONTAINER_ID bash -lc "/vagrant/createClusterAdlRoot.sh"
sudo docker exec -i $CONTAINER_ID bash -lc "hdfs dfs -ls /"

echo ***SN: restart services
sudo docker exec -i $CONTAINER_ID bash -lc "jps"
sudo docker exec -i $CONTAINER_ID bash -lc "sudo /vagrant/restart-bigtop.sh"
fi

echo ***SN: CLEAN UP TEST REPORT DIRS
sudo docker exec -i $CONTAINER_ID bash -lc "rm -r /bigtop/bigtop-tests/smoke-tests/$TESTDIR/build/reports/tests/*"

echo ***SN: TRIGGER SMOKE TEST
sudo docker exec -i $CONTAINER_ID bash -lc "/bigtop/bigtop-deploy/vm/utils/smoke-tests.sh $TESTDIR" > $WORK_SPACE/output.txt

echo ***SN: Generate XML
sudo ./generateReport.sh $WORK_SPACE

if [ "$DELETECLUSTER" = "true" ]; then
echo ***SN: DELETE CLUSTER
sudo docker exec -i $CONTAINER_ID bash -lc "/vagrant/deleteClusterAdlRoot.sh"
# clear the container and config
sudo docker stop $CONTAINER_ID
sudo docker rm $CONTAINER_ID
vagrantconfigfile="vagrantconfig$JOB_NAME.yaml"
sudo rm -f $vagrantconfigfile
fi
