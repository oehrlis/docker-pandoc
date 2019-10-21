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

# build docker image
docker build -t ${DOCKER_USER}/${IMAGE}:latest .

# generate PDF
echo "generate PDF sample file"
docker run --rm -v "$PWD":/workdir:z ${DOCKER_USER}/${IMAGE}:latest  \
--pdf-engine=xelatex --listings -o sample/sample.pdf sample/sample.md

# generate DOCX
echo "generate DOCX sample file"
docker run --rm -v "$PWD":/workdir:z ${DOCKER_USER}/${IMAGE}:latest  \
--listings -o sample/sample.docx sample/sample.md

# generate PPTX
echo "generate PPTX sample file"
docker run --rm -v "$PWD":/workdir:z ${DOCKER_USER}/${IMAGE}:latest  \
--listings -o sample/sample.pptx sample/sample.md

# change back to working directory
cd ${CURRENT_PATH}
# --- EOF --------------------------------------------------------------------