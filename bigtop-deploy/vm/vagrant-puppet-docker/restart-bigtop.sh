#!/bin/bash
#for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x restart ; done
sudo service hbase-regionserver restart
sudo service hbase-master restart
sudo service hbase-thrift restart

sudo service hadoop-yarn-resourcemanager restart
sudo service hadoop-yarn-nodemanager restart
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x restart ; done
sudo service hadoop-mapreduce-historyserver restart
sudo service hadoop-yarn-timelineserver restart
sudo service zookeeper-server restart
for x in `cd /etc/init.d ; ls spark-*` ; do sudo service $x restart ; done
sudo service zeppelin restart

# on hbase cluster jps would give
#3152 NodeManager
#3538 HMaster
#2196 DataNode
#1445 WebAppProxyServer
#4170 Jps
#2011 NameNode
#1164 QuorumPeerMain
#1564 ResourceManager
#3725 ThriftServer
#3373 HRegionServer
#1870 JobHistoryServer


