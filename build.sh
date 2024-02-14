#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.08.17
# Revision...: --
# Purpose....: Script to build Docker image
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# - Environment Variables ---------------------------------------------------
export DOCKER_USER="oehrlis"
export BUILD_CONTEXT="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
export PROJECT=$(basename ${BUILD_CONTEXT})
export IMAGE=$(echo ${PROJECT}|cut -d- -f2)
RELEASE=${1:-"beta"}
NOCACHE=${2:-""}
# - EOF Environment Variables -----------------------------------------------

# save current path
CURRENT_PATH=$(pwd)

# change to build context
cd ${BUILD_CONTEXT}

# build docker image
echo "Start multiplatform build $RELEASE"

# get release tags
if [ $RELEASE == "beta" ] ; then
    RELEASE_TAGS="-t ${DOCKER_USER}/${IMAGE}:$RELEASE"
else
    RELEASE_TAGS="-t ${DOCKER_USER}/${IMAGE}:$RELEASE -t ${DOCKER_USER}/${IMAGE}:latest"
fi

echo "build ----"
# start to build 
docker buildx build --push \
    ${NOCACHE} ${RELEASE_TAGS} \
    --platform=linux/amd64,linux/arm64 .

echo "Pull the image $RELEASE from the registry"
docker pull ${DOCKER_USER}/${IMAGE}:$RELEASE
# generate PDF
echo "generate PDF sample file"
docker run --rm -v "$PWD":/workdir:z ${DOCKER_USER}/${IMAGE}:$RELEASE  \
--metadata-file sample/metadata.yml --filter pandoc-latex-environment \
--resource-path=sample --pdf-engine=xelatex \
--listings -o sample/sample.pdf sample/sample.md

# generate DOCX
echo "generate DOCX sample file"
docker run --rm -v "$PWD":/workdir:z ${DOCKER_USER}/${IMAGE}:$RELEASE  \
--metadata-file sample/metadata.yml --resource-path=sample \
--listings -o sample/sample.docx sample/sample.md

# generate PPTX
echo "generate PPTX sample file"
docker run --rm -v "$PWD":/workdir:z ${DOCKER_USER}/${IMAGE}:$RELEASE  \
--metadata-file sample/metadata.yml --resource-path=sample \
--listings -o sample/sample.pptx sample/sample.md

# change back to working directory
cd ${CURRENT_PATH}
# --- EOF --------------------------------------------------------------------
