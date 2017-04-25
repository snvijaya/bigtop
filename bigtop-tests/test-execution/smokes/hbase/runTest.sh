export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export HADOOP_HOME=/usr/lib/hadoop
export HADOOP_CONF_DIR=/usr/lib/hadoop/conf
export HBASE_HOME=/usr/lib/hbase
export HBASE_CONF_DIR=/usr/lib/hbase/conf
export ZOOKEEPER_HOME=/usr/lib/zookeeper

cd /bigtop-home
mvn -f bigtop-tests/test-artifacts/pom.xml  install
mvn -f bigtop-tests/test-execution/conf/pom.xml  install
mvn -f bigtop-tests/test-execution/common/pom.xml  install
cd /bigtop-home/bigtop-tests/test-execution/smokes/hbase
mvn verify -Dorg.apache.maven-failsafe-plugin.testInclude=**/TestHBaseSmoke*
