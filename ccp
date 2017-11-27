#! /bin/bash
#==============================================================================
#title           :ccp
#description     :This script will compact and copy on the fly using parellel gzip between different servers. It is useful to reduce the data traffic on the network.
#author		 :Fabio Mota
#date            :20140602
#version         :1.0    
#usage		 :ccp user@SOURCE_HOST:path user@REMOTE_HOST:path
#notes           :Install pigz, nc and tar before use this script.
#bash_version    :4.1.5(1)-release
#==============================================================================



if ! type "nc" > /dev/null 2>/dev/null; then echo "The 'nc' program is not in PATH or is not installed. Try 'sudo apt-get install nc'";fi
if ! type "pigz" > /dev/null 2>/dev/null; then echo "The 'pigz' program is not in PATH or is not installed. 'Try sudo apt-get install pigz'";fi
if ! type "tar" > /dev/null 2>/dev/null; then echo "The 'tar' program is not in PATH or is not installed. Try 'sudo apt-get install tar'";fi


if [ x$2 == x"" ]; then echo "Use: ccp user@SOURCE_HOST:path user@REMOTE_HOST:path"
  exit 0; 
fi

if [[ "$1" =~ "@" ]]; then
    e=(`echo $1 | tr '@' ' '`);
    ORIG_USER="${e[0]}@"
    S=${e[1]}
    else
    S=$1
fi

if [[ "$2" =~ "@" ]]; then
    d=(`echo $2 | tr '@' ' '`);
    DEST_USER="${d[0]}@"
    D=${d[1]}
    else
    D=$2
fi



b=(`echo $S | tr ':' ' '`);
ORIG_HOST=${b[0]}
ORIG_FILE_FULL=${b[1]}

ORIG_FILE_DIR=$(dirname $ORIG_FILE_FULL)
ORIG_FILE_NAME=$(basename $ORIG_FILE_FULL)

a=(`echo $D | tr ':' ' '`)
DEST_HOST=${a[0]}

DEST_FILE_FULL=${a[1]}

DEST_FILE_DIR=$(dirname $DEST_FILE_FULL)
DEST_FILE_NAME=$(basename $DEST_FILE_FULL)

NC_PORT=1234

if ! ssh $ORIG_USER$ORIG_HOST stat $ORIG_FILE_FULL \> /dev/null 2\>\&1
    then
    echo "File $ORIG_FILE_NAME does not exist in source host ($ORIG_HOST:$ORIG_FILE_DIR)";exit;
fi

if ! ssh $DEST_USER$DEST_HOST stat $DEST_FILE_FULL \> /dev/null 2\>\&1
    then
    echo "It is not possible to copy to $DEST_FILE_FULL. This path does not exit in $DEST_HOST:$DEST_FILE_FULL";exit;
fi
				

ssh $ORIG_USER$ORIG_HOST "tar -c -C $ORIG_FILE_DIR $ORIG_FILE_NAME | pigz -9 | nc -l $NC_PORT > /dev/null &"; 
ssh $DEST_USER$DEST_HOST "cd $DEST_FILE_DIR; cd $DEST_FILE_FULL; nc $ORIG_HOST $NC_PORT | pigz -d | tar -xvf - " ;

