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
    echo "       -C file                                   		       Use alternate file for vagrantconfig.yaml"
    echo "  commands:"
    echo "       --create hostname ADLConfigXmlFile TestComponent ADLJarPath	Create a BT Docker"
    exit 1
}

create() {
    exec 3>create.lock
    flock -x 3

    host_name=$1
    AdlConfigLocalFileWithPath=$2
    SDK_JAR_PATH=$4
    DRIVER_JAR_PATH=$4
    DEFAULT_COMPONENTS="hadoop, yarn, mapred-app"
    COMPONENTS="[$DEFAULT_COMPONENTS, $3]"

    echo "SN: Start creation of $3 docker - $host_name using $AdlConfigLocalFileWithPath"
    echo "SN: using jars from : $SDK_JAR_PATH $DRIVER_JAR_PATH"
    ## VAGRANT CONFIG FILE UPDATE
    vagrantfilewithhost="vagrantconfig$host_name.yaml"
    cp $vagrantyamlconf $vagrantfilewithhost
    echo "components: $COMPONENTS" >>  $vagrantfilewithhost
    echo "name: \"$host_name\"" >> $vagrantfilewithhost
    echo "\$vagrantyamlconf = \"$vagrantfilewithhost\"" > config.rb
    vagrantyamlconf=$vagrantfilewithhost

    echo "SN: vagrant up start "
    sudo vagrant up 
    echo "SN: vagrant up end"
    if [ $? -ne 0 ]; then
        echo "Docker container(s) startup failed!";
	exit 1;
    fi

    TMPDIR="tmp.$host_name"
    sudo mkdir $TMPDIR
    sudo chmod 777 $TMPDIR
    ## BACKUP CORE CONFIG To RESTORE AT END
    sudo cp ../../puppet/modules/hadoop/templates/core-site.xml $TMPDIR/git_copy_core-site.xml
    
    nodes=(`sudo vagrant status |grep $host_name |awk '{print $1}'`)
    echo "SN: Node - $nodes is up"
    hadoop_head_node=(`echo "hostname -f" |vagrant ssh ${nodes[0]} |tail -n 1`)
    echo "SN: Headnode is $hadoop_head_node"
    repo=$(get-yaml-config repo)
    components="[`echo $(get-yaml-config components) | sed 's/ /, /g'`]"
    jdk=$(get-yaml-config jdk)
    distro=$(get-yaml-config distro)
    enable_local_repo=$(get-yaml-config enable_local_repo)

    CONTAINER_ID=$(docker ps -a | grep $host_name | awk '{print $1}')

    for node in ${nodes[*]}; do
        (
        echo "SN: $node calling setenv"
        sudo docker exec -i $CONTAINER_ID bash -lc "/bigtop-home/bigtop-deploy/vm/utils/setup-env-$distro.sh $enable_local_repo"
        echo "SN: $node: Triggering provision"
        sudo docker exec -i $CONTAINER_ID bash -lc "/vagrant/provision.sh $hadoop_head_node $repo \"$components\" $jdk"
        ) &
    done
    wait

    # run bigtop puppet (master node need to be provisioned before slave nodes)
    bigtop-puppet ${nodes[0]}
    for ((i=1 ; i<${#nodes[*]} ; i++)); do
        bigtop-puppet ${nodes[$i]} &
    done
    wait
    
     echo ***SN: update config
    AdlConfigfileName="${AdlConfigLocalFileWithPath##*/}"
    sudo cp ../../puppet/modules/hadoop/templates/base-core-site.xml $TMPDIR/orig-core-site.xml
    cp $AdlConfigLocalFileWithPath $TMPDIR/$AdlConfigfileName
    ConfigUpdate/reCreateCoreSite.sh $TMPDIR/orig-core-site.xml $TMPDIR/$AdlConfigfileName $TMPDIR/core-site.xml $host_name
    ConfigUpdate/copyCoreSiteToDocker.sh $CONTAINER_ID $TMPDIR/core-site.xml
    sudo cp $TMPDIR/git_copy_core-site.xml ../../puppet/modules/hadoop/templates/core-site.xml
    ConfigUpdate/updateHdfsSiteAtDocker.sh $CONTAINER_ID $host_name
    sudo rm -rf $TMPDIR

    exec 3>&-

    echo "SN: Removing older client jars. Causing problem with nodemanager crashing"
    sudo docker exec -i $CONTAINER_ID bash -lc "sudo rm -f /usr/lib/hadoop-mapreduce/*azure*"

    if [ $# -gt 3 ]; then
        if [ "$SDK_JAR_PATH" = "." ]; then
	 echo "SN: SDK jar path provided is current working directory"
	 SDK_JAR_PATH="$PWD/"
	fi	
        if [ "$DRIVER_JAR_PATH" = "." ]; then
         echo "SN: Driver jar path provided is current working directory"
         DRIVER_JAR_PATH="$PWD/"
        fi
        echo "SN: COPY JARS $CONTAINER_ID $COMPONENTS"
        sudo ./copyJars.sh $CONTAINER_ID $SDK_JAR_PATH $DRIVER_JAR_PATH $COMPONENTS
        echo "SN: JAR COPY VERIFY"
        sudo docker exec -i $CONTAINER_ID bash -lc "ls /usr/lib/hadoop/lib/ | grep azure"

        echo "SN: CREATE CLUSTER ADL ROOT"
        sudo docker exec -i $CONTAINER_ID bash -lc "/vagrant/createClusterAdlRoot.sh"
        echo "SN: VERIFY CLUSTER ROOT EXISTANCE"
        sudo docker exec -i $CONTAINER_ID bash -lc "hdfs dfs -ls /"
        echo "SN: PROCESSES RUNNING"
        sudo docker exec -i $CONTAINER_ID bash -lc "jps"
        echo "SN: RESTART SERVICES"
    fi

    echo "SN: CLONE BIGTOP HOME"
    sudo docker exec -i $CONTAINER_ID bash -lc "cp -r /bigtop-home /bigtop"
    echo "SN: SETTING UP SHORTCUT ALIAS IN DOCKER"
    sudo docker exec -i $CONTAINER_ID bash -lc "cat /vagrant/adlHelperScripts/dockerAlias.sh >> ~/.bashrc"
    sudo docker exec -i $CONTAINER_ID bash -lc "source ~/.bashrc"
}

bigtop-puppet() {
        echo ***SN:bigtop-puppet
        sudo docker exec -i $CONTAINER_ID bash -lc "puppet apply -d  --parser future --modulepath=/bigtop-home/bigtop-deploy/puppet/modules:/etc/puppet/modules /bigtop-home/bigtop-deploy/puppet/manifests"
#    echo "puppet apply -d  --parser future --modulepath=/bigtop-home/bigtop-deploy/puppet/modules:/etc/puppet/modules /bigtop-home/bigtop-deploy/puppet/manifests" |vagrant ssh $1
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
        if [ $# -lt 3 ]; then
          echo "Create requires hostname and ADL Config file with path" 1>&2
          usage
        fi
        
	if [ $# -eq 3 ]; then
         create $2 $3
	fi
 
        if [ $# -gt 3 ]; then
	  create $2 $3 $4 $5 
          shift 2;
	fi
 
        shift 3;;
    -C|--conf)
        if [ $# -lt 2 ]; then
          echo "Alternative config file for vagrantconfig.yaml" 1>&2
          usage
        fi
	vagrantyamlconf=$2
        shift 2;;
    -h|--help)
        usage
        shift;;
    *)
        echo "Unknown argument: '$1'" 1>&2
        usage;;
    esac
done
