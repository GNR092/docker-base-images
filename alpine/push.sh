#!/bin/bash
./build.sh

docker tag gnr092/base:alpine gnr092/base:alpine
docker push gnr092/base:alpine