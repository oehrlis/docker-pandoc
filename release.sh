#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: build.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.10.21
# Revision...: 
# Purpose....: Script to build Docker image.
# Notes......: --
# Reference..: --
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
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

# save current path
CURRENT_PATH=$(pwd)

# change to build context
cd ${BUILD_CONTEXT}

# ensure we're up to date
git pull

# bump version
docker run --rm -v "$PWD":/app treeder/bump patch
version=`cat VERSION`
echo "version: $version"

# run build
./build.sh

# tag it
git add -A
git commit -m "version $version"
git tag -a "$version" -m "version $version"
git push
git push --tags
docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$version
# push it
docker push $USERNAME/$IMAGE:latest
docker push $USERNAME/$IMAGE:$version

# change back to working directory
cd ${CURRENT_PATH}
# --- EOF --------------------------------------------------------------------