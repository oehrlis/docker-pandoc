#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
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

# save current path
CURRENT_PATH=$(pwd)

# change to build context
cd ${BUILD_CONTEXT}

#export DOCKER_BUILDKIT=1
# build docker image
echo "Start multiplatform build"
docker buildx build --no-cache --output=type=registry \
    -t ${DOCKER_USER}/${IMAGE}:latest \
    --platform=linux/amd64,linux/arm64 .

echo "Pull the image from the registry"
docker pull ${DOCKER_USER}/${IMAGE}:latest
# generate PDF
echo "generate PDF sample file"
docker run --rm -v "$PWD":/workdir:z ${DOCKER_USER}/${IMAGE}:beta  \
--metadata-file sample/metadata.yml --filter pandoc-latex-environment \
--resource-path=sample --pdf-engine=xelatex \
--listings -o sample/sample.pdf sample/sample.md

# generate DOCX
echo "generate DOCX sample file"
docker run --rm -v "$PWD":/workdir:z ${DOCKER_USER}/${IMAGE}:latest  \
--metadata-file sample/metadata.yml --resource-path=sample \
--listings -o sample/sample.docx sample/sample.md

# generate PPTX
echo "generate PPTX sample file"
docker run --rm -v "$PWD":/workdir:z ${DOCKER_USER}/${IMAGE}:latest  \
--metadata-file sample/metadata.yml --resource-path=sample \
--listings -o sample/sample.pptx sample/sample.md

# change back to working directory
cd ${CURRENT_PATH}
# --- EOF --------------------------------------------------------------------
