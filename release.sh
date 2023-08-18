#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: relase.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.08.17
# Revision...: --
# Purpose....: Script to release Docker image
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# - Environment Variables ------------------------------------------------------
export DOCKER_USER="oehrlis"
export BUILD_CONTEXT="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
export PROJECT=$(basename ${BUILD_CONTEXT})
export IMAGE=$(echo ${PROJECT}|cut -d- -f2)
# - EOF Environment Variables --------------------------------------------------
REL_TYPE=${1:-"patch"}  # could be also minor or major
NOCACHE=${2:-""}
REL_TYPE=$(echo "$REL_TYPE" | tr '[:upper:]' '[:lower:]')

# save current path
CURRENT_PATH=$(pwd)

# change to build context
cd ${BUILD_CONTEXT}

# ensure we're up to date
git pull

# bump version
pre_version=$(cat VERSION)
docker run --rm -v "$PWD":/app treeder/bump $REL_TYPE

version=$(cat VERSION)
echo "version: $version"

# run build
./build.sh $version $NOCACHE

# tag it
git add -A
git commit -m "version $version"
git tag -a "$version" -m "version $version"
git push
git push --tags

# change back to working directory
cd ${CURRENT_PATH}
# --- EOF ----------------------------------------------------------------------