BIGTOP_GIT_HOME="/home/hadoop/ADLBigtop"

# DIRECTORY ALIASES
dockerPath="$BIGTOP_GIT_HOME/bigtop-deploy/vm/vagrant-puppet-docker"
adlScriptPath="$dockerPath/adlHelperScripts"
alias scriptDir="cd $BIGTOP_GIT_HOME/bigtop-deploy/puppet/modules/hadoop/templates/"
alias dockerDir="cd $dockerPath"
alias bigtop="cd $BIGTOP_GIT_HOME"

alias jenkins='cd /var/lib/jenkins/workspace'


# DOCKER COMMANDS
alias rmDockers="cd $adlScriptPath;./clearAllDockers.sh;cd -" 
alias dockers='sudo docker ps -a'

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
export JRE_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64/bin

dockID() {
     sudo docker exec -it $1 bash
}

dockName() {
     sudo docker exec -it $(docker ps -a | grep $1 | awk '{print $1}') bash
}

# GIT COMMANDS
alias gd='git diff'
alias gs='git status'

