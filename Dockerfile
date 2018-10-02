# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.19
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
FROM oraclelinux:7-slim

# Maintainer
# ----------------------------------------------------------------------
LABEL maintainer="stefan.oehrli@trivadis.com"

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV WORKDIR=/workdir \
    PATH=/usr/local/texlive/2018/bin/x86_64-linux:$PATH

# copy the texlife profile
COPY texlive.profile /tmp/texlive.profile

# RUN as user root
# ----------------------------------------------------------------------
# install packages used to run texlive install stuff
# - ugrade system
# - install wget tar gzip perl perl-core
# - download texlive installer
# - initiate basic texlive installation
# - add a couple of custom package via tlmgr
# - clean up tlmgr, yum and other stuff
RUN echo "%_install_langs   en" >/etc/rpm/macros.lang && \
    yum -y upgrade && \
    yum -y install wget perl tar gzip zip unzip perl-core && \
    mkdir /tmp/texlive && \
    curl -Lsf http://www.pirbot.com/mirrors/ctan/systems/texlive/tlnet/install-tl-unx.tar.gz \
        | tar zxvf - --strip-components 1 -C /tmp/texlive/ && \
    /tmp/texlive/install-tl --profile=/tmp/texlive.profile  && \
    tlmgr install koma-script float ly1 \
                lm ec listings times mweights \
                sourcecodepro titling setspace \
                xcolor csquotes etoolbox caption \
                mdframed l3packages l3kernel draftwatermark \
                everypage minitoc breakurl lastpage \ 
                datetime fmtcount blindtext fourier textpos \
                needspace sourcesanspro xkeyval && \
    tlmgr backup --clean --all && \
    curl -f http://tug.org/fonts/getnonfreefonts/install-getnonfreefonts \
        -o /tmp/install-getnonfreefonts && \
    texlua /tmp/install-getnonfreefonts && \
    getnonfreefonts --sys -a && \
    yum -y erase wget zip unzip perl perl-core && \
    yum clean all && \
    rm -rv /tmp/texlive /tmp/texlive.profile /tmp/install* && \
    rm -rf /var/cache/yum && \
    rm /usr/local/texlive/*/tlpkg/texlive.tlpdb.*

# install pandoc from github
RUN PANDOC_URL=$(curl -s https://api.github.com/repos/jgm/pandoc/releases/latest \
        | grep 'browser_download.*pandoc-.*-linux.tar.gz' \
        | cut -d: -f 2,3 | tr -d '"' ) && \
    curl -Lsf ${PANDOC_URL} \
        | tar zxvf - --strip-components 2 -C /usr/local/bin && \
    rm -rf /usr/local/bin/man && \
    mkdir ${WORKDIR}

# Define /texlive as volume
VOLUME ["${WORKDIR}"]

# set workding directory
WORKDIR "${WORKDIR}"

# Define default command to start OUD instance
CMD exec "/usr/local/bin/pandoc"
# --- EOF --------------------------------------------------------------