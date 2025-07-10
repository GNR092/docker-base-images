#!/bin/bash
./build.sh

docker tag gnr092/base:alpine-steamcmd gnr092/base:alpine-steamcmd
docker push gnr092/base:alpine-steamcmd