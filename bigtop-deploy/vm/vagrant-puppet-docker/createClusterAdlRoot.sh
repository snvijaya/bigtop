#set -x
mkdir -p $DOCKER_HOST
cat /etc/hadoop/conf/core-site.xml | grep azuredatalake > tmp.account.config
config=$(cat /etc/hadoop/conf/core-site.xml | grep azuredatalake)
echo $config
line=$(head -n 1 tmp.account.config)
adlaccounthost=$(echo $line | sed -r 's/<\/value>//g' | sed -r 's/<value>//g')
echo $adlaccounthost

## create Clusters if not already there
adlpath="adl://$adlaccounthost/"
echo $adlpath	
mkdir -p Clusters
hdfs dfs -copyFromLocal Clusters $adlpath


## create Cluster root if not already there
adlClustersPath="adl://$adlaccounthost/Clusters/"
echo $adlClustersPath
#adlClusterRootPath="$adlClustersPath/$DOCKER_HOST"
#echo $adlClusterRootPath
mkdir -p $DOCKER_HOST
hdfs dfs -copyFromLocal $DOCKER_HOST $adlClustersPath

