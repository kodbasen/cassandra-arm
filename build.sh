#!/bin/bash

################################################################################
# init
################################################################################
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKDIR=$BASEDIR/.work
FILESDIR=$WORKDIR/files
IMG="gcr.io/google-samples/cassandra:v11"
CAS_VERSION="3.9"
DIST_FILE=apache-cassandra-$CAS_VERSION-bin.tar.gz
DIST_URL=http://archive.apache.org/dist/cassandra/$CAS_VERSION/$DIST_FILE

################################################################################
# common
################################################################################
cas:log() {
  timestamp=$(date +"[%m%d %H:%M:%S]")
  echo "+++ cas $timestamp $1"
  shift
  for message; do
    echo "    $message"
  done
}

cas::copy_from_parent_container() {
  docker pull $IMG
  set +e
  docker rm -f cassandra-template
  set -e
  docker create --name=cassandra-template $IMG
  for i in kubernetes-cassandra.jar run.sh ready-probe.sh etc/cassandra; do
    cas:log "copying $i from $IMG"
    docker cp cassandra-template:/$i $FILESDIR
  done
}

cas::download() {
  if [ ! -f "$FILESDIR/apache-cassandra-$CAS_VERSION-bin.tar.gz" ]; then
    cas:log "downloading cassandra $CAS_VERSION ..."
    cd $FILESDIR
    curl -sSLO $DIST_URL
    cd $BASEDIR
    cas:log "downloading cassandra $CAS_VERSION done!"
  fi
}

cas::create_dockerfile() {
  rm -f $BASEDIR/Dockerfile
  cp $BASEDIR/Dockerfile.template $BASEDIR/Dockerfile
  sed -i -e "s;cassandra.version;$CAS_VERSION;" "Dockerfile"
  sed -i -e "s;cassandra.dist.file;.work/files/$DIST_FILE;" "Dockerfile"
  sed -i -e "s;cassandra.etc.dir;.work/files/cassandra;" "Dockerfile"
}

cas::build_docker_image() {
  cas:log "building docker image ..."
  docker build --rm=true --no-cache -t kodbasen/cassandra-arm:latest .
  cas:log "done building image!"
}

cas::export_and_extract_image() {
  cas:log "exporting image ..."
  rm cassandra.*.tar
  CONTAINER_NAME=cassandra.$RANDOM
  docker create --name=$CONTAINER_NAME kodbasen/cassandra-arm:latest true
  docker export $CONTAINER_NAME > $CONTAINER_NAME.tar
  docker rm $CONTAINER_NAME
  cas:log "export done!"
}
################################################################################
# main
################################################################################
echo " ____ ____ ____ ____ ____ ____ ____ ____ ";
echo "||k |||o |||d |||b |||a |||s |||e |||n ||";
echo "||__|||__|||__|||__|||__|||__|||__|||__||";
echo "|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|";
echo ""

mkdir -p $FILESDIR
cas::download
cas::create_dockerfile
cas::build_docker_image
cas::export_and_extract_image
#cas::copy_from_parent_container
#cas::download
#cas::build_docker_image
