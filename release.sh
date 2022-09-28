#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: relase.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.10.21
# Revision...: 
# Purpose....: Script to release Docker image.
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------

# - Environment Variables ---------------------------------------------------
export DOCKER_USER="oehrlis"
export BUILD_CONTEXT="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
export PROJECT=$(basename ${BUILD_CONTEXT})
export IMAGE=$(echo ${PROJECT}|cut -d- -f2)
# - EOF Environment Variables -----------------------------------------------
REL_TYPE=${1:-"patch"}  # could be also minor or major
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
./build.sh $version

# tag it
git add -A
git commit -m "version $version"
git tag -a "$version" -m "version $version"
git push
git push --tags

# change back to working directory
cd ${CURRENT_PATH}
# --- EOF --------------------------------------------------------------------