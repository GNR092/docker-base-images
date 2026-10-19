#!/bin/bash
clear
docker build "$@" -f Dockerfile.python.optimized -t gnr092/weblvl:py-xdebug .
docker build "$@" -f Dockerfile.python.worker -t gnr092/weblaravel:pypsgl-worker .
