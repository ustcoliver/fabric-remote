#!/bin/bash
. scripts/utils.sh

type=$1
shift 
# 根据不同类型，清除文件或docker容器
case $type in
    "file")
        files=$@
        removeFiles $files
        ;;
    "docker")
        domain=$1
        removeContainer $domain 
        ;;
    *)
        fatalln "Usage: $0 [file|docker] [files|domain]"
        ;;
esac
