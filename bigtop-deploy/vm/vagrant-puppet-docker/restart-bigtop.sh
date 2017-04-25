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
