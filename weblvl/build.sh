#!/bin/bash
clear
docker build "$@" -f Dockerfile.python.worker -t gnr092/weblaravel:pypsgl-worker .
