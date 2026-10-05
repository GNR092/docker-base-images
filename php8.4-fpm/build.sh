#!/bin/bash
clear
docker build "$@" -t gnr092/base:php8.4-fpm .
