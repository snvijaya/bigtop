set -x
# PASS 4  ARGUMENTS
# 1 -> COMPONENT DIRECTORY NAME
# 2 -> {WORKSPACE}
# 3 -> {JOB_NAME}
# 4 -> {BUILD_NUMBER}

# INPUTS 
TESTDIR=$1
WORK_SPACE=$2
JOB_NAME=$3
BUILD_NUMBER=$4
CONFIG_DIR=$5

# Create vagrant docker
cd $CONFIG_DIR
sudo ./singleNodeHadoop.sh --create $JOB_NAME

# OUTPUT FILES
resultFile="result-$JOB_NAME-$BUILD_NUMBER.xml"
htmlReport="htmlReport-$JOB_NAME-$BUILD_NUMBER"

echo ***WORKSPACE= $WORK_SPACE
echo ***PWD = $PWD
echo ***JOB = $JOB_NAME

cd $WORK_SPACE

# BACKUP
mkdir -p $WORK_SPACE/older_run_archive
# BACKUP RESULT XML
if ls $WORK_SPACE/result* 1> /dev/null 2>&1; then
	sudo mv result-* $WORK_SPACE/older_run_archive
fi
# BACKUP HTML 	
if ls htmlReport-* 1> /dev/null 2>&1; then
	sudo mv -v $WORK_SPACE/htmlReport-* $WORK_SPACE/older_run_archive
fi

# RUN TEST
cd $CONFIG_DIR
CONTAINER_ID=$(docker ps -a | grep $JOB_NAME | awk '{print $1}')
echo ***CONTAINER USED FOR TESTING = $CONTAINER_ID ==> $(docker ps -a | grep $JOB_NAME | awk '{print $7}')
sudo docker exec -i $CONTAINER_ID bash -lc "rm -r /bigtop-home/bigtop-tests/smoke-tests/$TESTDIR/build/reports/tests/*"
sudo docker exec -i $CONTAINER_ID bash -lc "/bigtop-home/bigtop-deploy/vm/utils/smoke-tests.sh $TESTDIR"

# COLLECT OUTPUT
sudo docker exec -i $CONTAINER_ID bash -lc "cat /bigtop-home/bigtop-tests/smoke-tests/$TESTDIR/build/test-results/TEST-*" > $WORK_SPACE/${resultFile}
sudo docker exec -i $CONTAINER_ID bash -lc "mkdir -p /vagrant/htmlreport/$htmlReport"
sudo docker exec -i $CONTAINER_ID bash -lc "cp -r /bigtop-home/bigtop-tests/smoke-tests/$TESTDIR/build/reports/tests/* /vagrant/htmlreport/$htmlReport" 
sudo mv htmlreport/$htmlReport $WORK_SPACE/

# clear the container and config
sudo docker stop $CONTAINER_ID
sudo docker rm $CONTAINER_ID
vagrantconfigfile="vagrantconfig$JOB_NAME.yaml"
sudo rm -f $vagrantconfigfile
