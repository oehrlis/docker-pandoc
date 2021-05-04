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
FROM alpine:3.12.0

# Maintainer
# ----------------------------------------------------------------------
LABEL maintainer="stefan.oehrli@trivadis.com"

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV WORKDIR="/workdir" \
    PATH=/usr/local/texlive/bin/x86_64-linuxmusl:$PATH

# copy the texlife profile
COPY texlive.profile /tmp/texlive.profile

# RUN as user root
# ----------------------------------------------------------------------
# install additional alpine packages 
# - ugrade system
# - install wget tar gzip perl perl-core
RUN apk update && apk upgrade && apk add --update --no-cache \
        wget msttcorefonts-installer xz musl curl ghostscript perl \
        tar gzip zip unzip freetype lua fontconfig python3 py-pip && \
    rm -rf /var/cache/apk/*

# RUN as user root
# ----------------------------------------------------------------------
# install basic texlive and additonal packages
# - download texlive installer
# - initiate basic texlive installation
# - add a couple of custom package via tlmgr 
# - clean up tlmgr, apk and other stuff
# search for package tlmgr search --global --file
RUN mkdir /tmp/texlive && \
    curl -Lf http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
        | tar zxvf - --strip-components 1 -C /tmp/texlive/ && \
    /tmp/texlive/install-tl --profile /tmp/texlive.profile -repository http://mirror.ctan.org/systems/texlive/tlnet && \
    tlmgr install \
        ttfutils fontinst \
        fvextra footnotebackref times pdftexcmds \
        helvetic symbol grffile zapfding ly1 lm-math \
        soul sectsty titlesec xetex ec mweights \
        sourcecodepro titling csquotes  \
        mdframed draftwatermark mdwtools \
        everypage awesomebox tcolorbox environ minitoc fontawesome5 breakurl lastpage \
        datetime fmtcount blindtext fourier textpos \
        needspace sourcesanspro pagecolor epstopdf \
        letltxmacro zref background filehook ucharcat \
        adjustbox collectbox ulem bidi upquote xecjk xurl \
        framed babel-german footmisc unicode-math && \
    tlmgr backup --clean --all && \
    curl -f http://tug.org/fonts/getnonfreefonts/install-getnonfreefonts \
        -o /tmp/install-getnonfreefonts && \
    texlua /tmp/install-getnonfreefonts && \
    getnonfreefonts --sys arial-urw 
    # && \ 
    # rm -rv /tmp/texlive /tmp/texlive.profile /tmp/install* && \
    # rm -rv /usr/local/texlive/*/tlpkg/texlive.tlpdb.* && \
    # rm -rv /usr/local/texlive/bin/x86_64-linux && \
    # find / -name *.exe -exec rm -rv {} \; && \
    # find / -name *.log -exec rm -rv {} \;

# RUN as user root
# ----------------------------------------------------------------------
# google fonts and update font cache
RUN curl -Lf -o /tmp/nunito.zip https://fonts.google.com/download?family=Nunito && \
    curl -Lf -o /tmp/nunito_sans.zip https://fonts.google.com/download?family=Nunito%20Sans && \
    curl -Lf -o /tmp/Open_Sans.zip https://fonts.google.com/download?family=Open+Sans && \
    curl -Lf -o /tmp/Montserrat.zip https://fonts.google.com/download?family=Montserrat && \
    unzip -o -d /usr/share/fonts/custom/ /tmp/nunito.zip && \
    unzip -o -d /usr/share/fonts/custom/ /tmp/nunito_sans.zip && \
    unzip -o -d /usr/share/fonts/custom/ /tmp/Open_Sans.zip && \
    unzip -o -d /usr/share/fonts/custom/ /tmp/Montserrat.zip && \
    update-ms-fonts && \
    fc-cache -fv && \
    rm -rv /tmp/*.zip

# RUN as user root
# ----------------------------------------------------------------------
# install pandoc from github
RUN PANDOC_URL=$(curl -s https://api.github.com/repos/jgm/pandoc/releases/latest \
        | grep 'browser_download.*pandoc-.*-linux.*.tar.gz' \
        | cut -d: -f 2,3 | tr -d '"' ) && \
    curl -Lf ${PANDOC_URL} \
        | tar zxvf - --strip-components 2 -C /usr/local/bin && \
    rm -rf /usr/local/bin/man /usr/local/bin//pandoc-citeproc && \
    pip install pandoc-latex-color && \
    pip install pandoc-include && \
    pip install pandoc-latex-environment && \
    mkdir -p ${WORKDIR}

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV GITHUB_URL="https://github.com/oehrlis/pandoc_template/raw/master/" \
    PANDOC_DATA="/root/.local/share/pandoc" \
    XDG_DATA_HOME="/root/.local/share" \
    PANDOC_TEMPLATES="/root/.local/share/pandoc/templates" \
    PANDOC_IMAGES="/root/.local/share/pandoc/images" \
    TRIVADIS_TEMPLATES="/trivadis/templates"  \
    TRIVADIS_IMAGES="/trivadis/images" \
    TRIVADIS_TEX="trivadis.tex" \
    TRIVADIS_DOCX="trivadis.docx" \
    TRIVADIS_PPTX="trivadis.pptx" \
    TRIVADIS_LATEX="trivadis.latex" \
    TRIVADIS_HTML="GitHub.html5" \
    TRIVADIS_LOGO="TVDLogo2019.eps" \
    TEST="eesdf"

# install the trivadis LaTeX template from github and adjust the default logo
RUN mkdir -p ${TRIVADIS_TEMPLATES} ${TRIVADIS_IMAGES} ${PANDOC_DATA} \
        ${PANDOC_TEMPLATES} ${PANDOC_IMAGES} && \
    curl -Lf ${GITHUB_URL}/templates/${TRIVADIS_TEX}  -o ${TRIVADIS_TEMPLATES}/${TRIVADIS_TEX} && \
    curl -Lf ${GITHUB_URL}/templates/${TRIVADIS_DOCX} -o ${TRIVADIS_TEMPLATES}/${TRIVADIS_DOCX} && \
    curl -Lf ${GITHUB_URL}/templates/${TRIVADIS_PPTX} -o ${TRIVADIS_TEMPLATES}/${TRIVADIS_PPTX} && \
    curl -Lf ${GITHUB_URL}/templates/${TRIVADIS_HTML} -o ${TRIVADIS_TEMPLATES}/${TRIVADIS_HTML} && \
    curl -Lf ${GITHUB_URL}/images/${TRIVADIS_LOGO}    -o ${TRIVADIS_IMAGES}/${TRIVADIS_LOGO} && \
    curl -Lf ${GITHUB_URL}/images/TVDLogo2019-eps-converted-to.pdf -o ${TRIVADIS_IMAGES}/TVDLogo2019-eps-converted-to.pdf && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_TEX} ${TRIVADIS_TEMPLATES}/${TRIVADIS_LATEX} && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_TEX} ${PANDOC_TEMPLATES}/default.latex && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_TEX} ${PANDOC_TEMPLATES}/${TRIVADIS_TEX} && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_LATEX} ${PANDOC_TEMPLATES}/${TRIVADIS_LATEX} && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_DOCX} ${PANDOC_TEMPLATES}/${TRIVADIS_DOCX} && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_DOCX} ${PANDOC_TEMPLATES}/default.docx && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_DOCX} ${PANDOC_DATA}/${TRIVADIS_DOCX} && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_DOCX} ${PANDOC_DATA}/reference.docx && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_PPTX} ${PANDOC_TEMPLATES}/${TRIVADIS_PPTX} && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_PPTX} ${PANDOC_TEMPLATES}/default.pptx && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_PPTX} ${PANDOC_DATA}/reference.pptx && \
    ln ${TRIVADIS_TEMPLATES}/${TRIVADIS_HTML} ${PANDOC_TEMPLATES}/${TRIVADIS_HTML} && \
    ln ${TRIVADIS_IMAGES}/${TRIVADIS_LOGO} /${TRIVADIS_LOGO}

# Define /texlive as volume
VOLUME ["${WORKDIR}"]

# set workding directory
WORKDIR "${WORKDIR}"

# set the ENTRYPOINT
ENTRYPOINT ["/usr/local/bin/pandoc"]

# Define default command for pandoc
CMD ["--help"]
# --- EOF --------------------------------------------------------------