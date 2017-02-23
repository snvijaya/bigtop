#set -x
mkdir -p $DOCKER_HOST
cat /etc/hadoop/conf/core-site.xml | grep azuredatalake > tmp.account.config
config=$(cat /etc/hadoop/conf/core-site.xml | grep azuredatalake)
echo $config
line=$(head -n 1 tmp.account.config)
adlaccounthost=$(echo $line | sed -r 's/<\/value>//g' | sed -r 's/<value>//g')
echo $adlaccounthost

## delete Cluster root if not already there
adlClusterRootPath="adl://$adlaccounthost/Clusters/$DOCKER_HOST"
echo $adlClusterRootPath
hdfs dfs -rm -r $adlClusterRootPath

