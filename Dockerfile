# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.19
# Revision...: 1.0
# Purpose....: Dockerfile to build a JSON utilities image
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
FROM alpine

# Maintainer
# ----------------------------------------------------------------------
LABEL maintainer="stefan.oehrli@trivadis.com"

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV WORKDIR="/workdir" \
    PATH=/usr/local/texlive/2019/bin/x86_64-linuxmusl:$PATH

# copy the texlife profile
COPY texlive.profile /tmp/texlive.profile

# copy custom fonts
COPY fonts/* /usr/share/fonts/custom/

# RUN as user root
# ----------------------------------------------------------------------
# install packages used to run texlive install stuff
# - ugrade system
# - install wget tar gzip perl perl-core
# - download texlive installer
# - initiate basic texlive installation
# - add a couple of custom package via tlmgr
# - clean up tlmgr, apk and other stuff
RUN apk update && apk upgrade && apk add --update --no-cache \
        wget curl ghostscript perl tar gzip zip unzip fontconfig && \
    mkdir /tmp/texlive && \
    curl -Lsf http://www.pirbot.com/mirrors/ctan/systems/texlive/tlnet/install-tl-unx.tar.gz \
        | tar zxvf - --strip-components 1 -C /tmp/texlive/ && \
    /tmp/texlive/install-tl --profile=/tmp/texlive.profile  && \
    tlmgr install \
        times helvetic symbol zapfding ly1 lm-math \
        titlesec xetex ec mweights \
        sourcecodepro titling csquotes  \
        mdframed draftwatermark \
        everypage minitoc breakurl lastpage \ 
        datetime fmtcount blindtext fourier textpos \
        needspace sourcesanspro pagecolor epstopdf \
        adjustbox collectbox && \
    tlmgr backup --clean --all && \
    curl -f http://tug.org/fonts/getnonfreefonts/install-getnonfreefonts \
        -o /tmp/install-getnonfreefonts && \
    texlua /tmp/install-getnonfreefonts && \
    getnonfreefonts --sys arial-urw && \
    fc-cache -fv && \ 
    rm -rv /tmp/texlive /tmp/texlive.profile /tmp/install* && \
    rm -rf /var/cache/apk/* && \
    rm /usr/local/texlive/*/tlpkg/texlive.tlpdb.*

# RUN as user root
# ----------------------------------------------------------------------
# install pandoc from github
RUN PANDOC_URL=$(curl -s https://api.github.com/repos/jgm/pandoc/releases/latest \
        | grep 'browser_download.*pandoc-.*-linux.tar.gz' \
        | cut -d: -f 2,3 | tr -d '"' ) && \
    curl -Lsf ${PANDOC_URL} \
        | tar zxvf - --strip-components 2 -C /usr/local/bin && \
    rm -rf /usr/local/bin/man /usr/local/bin//pandoc-citeproc && \
    mkdir -p ${WORKDIR}

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV GITHUB_URL="https://github.com/oehrlis/pandoc_template/raw/master/" \
    PANDOC_DATA="/root/.pandoc" \
    PANDOC_TEMPLATES="/root/.pandoc/templates" \
    PANDOC_IMAGES="/root/.pandoc/images" \
    TRIVADIS_TEX="trivadis.tex" \
    TRIVADIS_DOCX="trivadis.docx" \
    TRIVADIS_LATEX="trivadis.latex" \
    TRIVADIS_LOGO="TVDLogo2019.eps"

# install the trivadis LaTeX template from github and adjust the default logo
RUN mkdir -p ${PANDOC_DATA} ${PANDOC_TEMPLATES} ${PANDOC_IMAGES} && \
    curl -Lsf ${GITHUB_URL}/templates/${TRIVADIS_TEX} -o ${PANDOC_TEMPLATES}/${TRIVADIS_LATEX} && \
    curl -Lsf ${GITHUB_URL}/templates/${TRIVADIS_DOCX} -o ${PANDOC_TEMPLATES}/${TRIVADIS_DOCX} && \
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