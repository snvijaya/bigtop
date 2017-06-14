#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -x

usage() {
    echo "usage: $PROG [-C file ] args"
    echo "       -C file                                   Use alternate file for vagrantconfig.yaml"
    echo "  commands:"
    echo "       --create=NUM_INSTANCES host_name AdlConfigFile JarPath Component "
    echo "       -h, --help"
    exit 1
}

create() {
#    exec 3>create.lock
#    flock -x 3

    host_name=$2 
    AdlConfigLocalFileWithPath=$3
    SDK_JAR_PATH=$4
    DRIVER_JAR_PATH=$4
    DEFAULT_COMPONENTS="hadoop, yarn, pig, hive"
    COMPONENTS="[$DEFAULT_COMPONENTS, $5]"
    echo "Starting cluster as host=$host_name with $AdlConfigLocalFileWithPath using jars in $SDK_JAR_PATH.Components set will be $COMPONENTS"

    sudo mkdir -p $TMPDIR
    sudo chmod 777 $TMPDIR
    JARDIR="tmp.jar.$host_name"
    sudo mkdir -p $JARDIR
    sudo chmod 777 $JARDIR
    ## BACKUP CORE CONFIG To RESTORE AT END
    sudo cp ../../puppet/modules/hadoop/templates/core-site.xml $TMPDIR/git_copy_core-site.xml
    
    nodes=(`sudo vagrant status |grep $host_name |awk '{print $1}'`)
    hadoop_head_node=(`echo "hostname -f" |vagrant ssh ${nodes[0]} |tail -n 1`)
    repo=$(get-yaml-config repo)
    components="[`echo $(get-yaml-config components) | sed 's/ /, /g'`]"
    jdk=$(get-yaml-config jdk)
    distro=$(get-yaml-config distro)
    enable_local_repo=$(get-yaml-config enable_local_repo)

     echo ***SN: update config
    AdlConfigfileName="${AdlConfigLocalFileWithPath##*/}"
    sudo cp ../../puppet/modules/hadoop/templates/base-core-site.xml $TMPDIR/orig-core-site.xml
    cp $AdlConfigLocalFileWithPath $TMPDIR/$AdlConfigfileName
    ConfigUpdate/reCreateCoreSite.sh $TMPDIR/orig-core-site.xml $TMPDIR/$AdlConfigfileName $TMPDIR/core-site.xml $host_name
    echo *** SN: Final core-site
    cat $TMPDIR/core-site.xml
    
    if [ $# -gt 3 ]; then
        if [ "$SDK_JAR_PATH" = "." ]; then
         echo "SN: SDK jar path provided is current working directory"
         SDK_JAR_PATH="$PWD/"
        fi
        if [ "$DRIVER_JAR_PATH" = "." ]; then
         echo "SN: Driver jar path provided is current working directory"
         DRIVER_JAR_PATH="$PWD/"
        fi
        sudo ./copyJars.sh $SDK_JAR_PATH $DRIVER_JAR_PATH $JARDIR $COMPONENTS
        echo "SN: Jars copied in host"
        ls $JARDIR
    fi

    for node in ${nodes[*]}; do
      (

        echo "jps"  |vagrant ssh $node
        echo "SN: Updating core site"
        echo "yes|cp -f /vagrant/$TMPDIR/core-site.xml /etc/hadoop/conf/core-site.xml" |vagrant ssh $node
        echo "cat /etc/hadoop/conf/core-site.xml" |vagrant ssh $node

        echo "SN: Updating hdfs-site.xml"
        echo "ls /etc/hadoop/conf" |vagrant ssh $node
        echo "sudo sed -i '/ADLSETUP/ d' /etc/hadoop/conf/hdfs-site.xml" |vagrant ssh $node
        echo "sed -i \"s/DOCKER_HOST/$host_name/g\" /etc/hadoop/conf/hdfs-site.xml" |vagrant ssh $node
        echo "cat /etc/hadoop/conf/hdfs-site.xml" |vagrant ssh $node

        echo "SN: removing old adl jars"
        echo "sudo rm -f /usr/lib/hadoop-mapreduce/*azure*" |vagrant ssh $node

        echo "SN: Copying jars to node"
        echo "yes | sudo cp -rf /vagrant/$JARDIR/* /usr/lib/hadoop/" |vagrant ssh $node
        echo "ls /usr/lib/hadoop/lib/ | grep azure" |vagrant ssh $node

        echo "SN: Enabling debug logs"
        echo "sudo sed -i -e '\$a log4j.logger.org.apache.hadoop=DEBUG' /etc/hadoop/conf/log4j.properties" |vagrant ssh $node
        echo "sudo sed -i -e '\$a log4j.logger.com.microsoft.azure.datalake.store=ALL' /etc/hadoop/conf/log4j.properties" |vagrant ssh $node
        echo "sudo sed -i -e '\$a log4j.logger.org.apache=DEBUG' /etc/hadoop/conf/log4j.properties" |vagrant ssh $node

        echo "SN: Creating adl cluster root"
        echo "echo \"export DOCKER_HOST=$host_name\" >>  ~/.bashrc" |vagrant ssh $node
        echo "source ~/.bashrc" |vagrant ssh $node
        echo "echo \$DOCKER_HOST" |vagrant ssh $node
        echo "/vagrant/createClusterAdlRoot.sh" |vagrant ssh $node
        echo "hdfs dfs -ls /" |vagrant ssh $node
        echo "jps" |vagrant ssh $node
        echo "/vagrant/restart-bigtop.sh" |vagrant ssh $node
        echo "jps" |vagrant ssh $node          

        echo "SN: Setting node directory alias"
        echo "cat /vagrant/adlHelperScripts/dockerAlias.sh >> ~/.bashrc" |vagrant ssh $node
        echo "source ~/.bashrc" |vagrant ssh $node
        ) &
    done
    wait

	sudo cp $TMPDIR/git_copy_core-site.xml ../../puppet/modules/hadoop/templates/core-site.xml
	sudo rm -rf $TMPDIR
        sudo rm -rf $JARDIR
#	exec 3>&-
}

provision() {
    nodes=(`vagrant status |grep bigtop |awk '{print $1}'`)
    for node in ${nodes[*]}; do
        bigtop-puppet $node &
    done
    wait
}

smoke-tests() {
    nodes=(`vagrant status |grep bigtop |awk '{print $1}'`)
    smoke_test_components="`echo $(get-yaml-config smoke_test_components) | sed 's/ /,/g'`"
    echo "/bigtop-home/bigtop-deploy/vm/utils/smoke-tests.sh \"$smoke_test_components\"" |vagrant ssh ${nodes[0]}
}


destroy() {
    vagrant destroy -f
    rm -rvf ./hosts ./config.rb
}

bigtop-puppet() {
    echo "puppet apply -d --modulepath=/bigtop-home/bigtop-deploy/puppet/modules:/etc/puppet/modules /bigtop-home/bigtop-deploy/puppet/manifests/site.pp" |vagrant ssh $1
}

get-yaml-config() {
    RUBY_EXE=ruby
    which ruby > /dev/null 2>&1
    if [ $? -ne 0 ]; then
	# use vagrant embedded ruby on Windows
        RUBY_EXE=$(dirname $(which vagrant))/../embedded/bin/ruby
    fi
    RUBY_SCRIPT="data = YAML::load(STDIN.read); puts data['$1'];"
    cat ${vagrantyamlconf} | $RUBY_EXE -ryaml -e "$RUBY_SCRIPT" | tr -d '\r'
}

PROG=`basename $0`

if [ $# -eq 0 ]; then
    usage
fi

vagrantyamlconf="vagrantconfig.yaml"
while [ $# -gt 0 ]; do
    case "$1" in
    -c|--create)
        if [ $# -lt 4 ]; then
          echo "Create requires number of nodes, hostname and ADL config file with path" 1>&2
          usage
        fi

        if [ $# -eq 4 ]; then
         create $2 $3 $4
        fi

        if [ $# -gt 4 ]; then
          create $2 $3 $4 $5 $6
          shift 2;
        fi

        shift 4;;


    -C|--conf)
        if [ $# -lt 2 ]; then
          echo "Alternative config file for vagrantconfig.yaml" 1>&2
          usage
        fi
	vagrantyamlconf=$2
        shift 2;;
    -p|--provision)
        provision
        shift;;
    -s|--smoke-tests)
        smoke-tests
        shift;;
    -d|--destroy)
        destroy
        shift;;
    -h|--help)
        usage
        shift;;
    *)
        echo "Unknown argument: '$1'" 1>&2
        usage;;
    esac
done
