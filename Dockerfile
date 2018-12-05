# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.12.05
# Revision...: 1.0
# Purpose....: Dockerfile to build a latex and pandoc image
# Notes......: --
# Reference..: --
# License....: Licensed under the Universal Permissive License v 1.0 as
#              shown at http://oss.oracle.com/licenses/upl.
# ----------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ----------------------------------------------------------------------

# Pull base image
# ----------------------------------------------------------------------
FROM oehrlis/latex

# Maintainer
# ----------------------------------------------------------------------
LABEL maintainer="stefan.oehrli@trivadis.com"

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV WORKDIR="/workdir" \
    PATH=/usr/local/texlive/2018/bin/x86_64-linux:$PATH \
    GITHUB_URL="https://github.com/oehrlis/pandoc_template/raw/master/" \
    PANDOC_DATA="/root/.pandoc" \
    PANDOC_TEMPLATES="/root/.pandoc/templates" \
    PANDOC_IMAGES="/root/.pandoc/images" \
    TRIVADIS_TEX="trivadis.tex" \
    TRIVADIS_LATEX="trivadis.latex" \
    TRIVADIS_LOGO="TVDLogo2019.eps"

# RUN as user root
# ----------------------------------------------------------------------
# install pandoc from github
RUN PANDOC_URL=$(curl -s https://api.github.com/repos/jgm/pandoc/releases/latest \
        | grep 'browser_download.*pandoc-.*-linux.tar.gz' \
        | cut -d: -f 2,3 | tr -d '"' ) && \
    curl -Lsf ${PANDOC_URL} \
        | tar zxvf - --strip-components 2 -C /usr/local/bin && \
    rm -rf /usr/local/bin/man && \
    mkdir -p ${WORKDIR}

# install the trivadis LaTeX template from github and adjust the default logo
RUN mkdir -p ${PANDOC_DATA} ${PANDOC_TEMPLATES} ${PANDOC_IMAGES} && \
    curl -Lsf ${GITHUB_URL}/${TRIVADIS_TEX} -o ${PANDOC_TEMPLATES}/${TRIVADIS_LATEX} && \
    curl -Lsf ${GITHUB_URL}/images/${TRIVADIS_LOGO} -o ${PANDOC_IMAGES}/${TRIVADIS_LOGO} && \
    curl -Lsf ${GITHUB_URL}/images/TVDLogo2019-eps-converted-to.pdf -o ${PANDOC_IMAGES}/TVDLogo2019-eps-converted-to.pdf && \
    sed -i "s|images/${TRIVADIS_LOGO}|${PANDOC_IMAGES}/${TRIVADIS_LOGO}|" ${PANDOC_TEMPLATES}/${TRIVADIS_LATEX}

# Define /texlive as volume
VOLUME ["${WORKDIR}"]

# set workding directory
WORKDIR "${WORKDIR}"

# set the ENTRYPOINT
ENTRYPOINT ["/usr/local/bin/pandoc"]

# Define default command for pandoc
CMD ["--help"]
# --- EOF --------------------------------------------------------------