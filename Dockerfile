# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.08.17
# Revision...: --
# Purpose....: Dockerfile to build the pandoc image
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Pull base image
# ------------------------------------------------------------------------------
FROM ubuntu
ARG TARGETPLATFORM
ARG TARGETARCH
# Maintainer
# ------------------------------------------------------------------------------
LABEL maintainer="stefan.oehrli@accenture.com"

# Environment variables required for this build (do NOT change)
# ------------------------------------------------------------------------------
ENV PATH=/usr/local/texlive/bin/aarch64-linux:$PATH
ENV PATH=/usr/local/texlive/bin/x86_64-linux:$PATH
ENV WORKDIR="/workdir" \
    DEBIAN_FRONTEND="noninteractive" \
    GITHUB_URL="https://github.com/oehrlis/pandoc_template/archive/refs/heads/master.tar.gz" \
    PANDOC_DATA="/root/.local/share/pandoc" \
    XDG_DATA_HOME="/root/.local/share" \
    ORADBA="/oradba"

# copy the texlife profile
RUN echo "I'm building for ${TARGETPLATFORM} using ${TARGETARCH}"
# RUN echo "I'm building using $TARGETARCH"
COPY texlive.$TARGETARCH.profile /tmp/texlive.profile

# RUN as user root
# ------------------------------------------------------------------------------
# install additional alpine packages 
# - ugrade system
RUN echo "Performing initial clean-up and updates for base image." && \
    apt-get -y update && \
    apt-get -y --fix-missing --no-install-recommends install && \
    apt-get -y --with-new-pkgs --no-install-recommends upgrade && \
# - prevent doc and man pages from being installed
#   the idea is based on https://askubuntu.com/questions/129566
    echo "Preventing documentation and man-pages from being installed." && \
    printf 'path-exclude /usr/share/doc/*\npath-include /usr/share/doc/*/copyright\npath-exclude /usr/share/man/*\npath-exclude /usr/share/groff/*\npath-exclude /usr/share/info/*\npath-exclude /usr/share/lintian/*\npath-exclude /usr/share/linda/*\npath-exclude=/usr/share/locale/*' > /etc/dpkg/dpkg.cfg.d/01_nodoc && \
# - install apt utilities
    echo "Installing utilities." && \
    apt-get install -f -y --no-install-recommends apt-utils && \
# - get and update certificates, to hopefully resolve mscorefonts error
    echo "Getting and updating certificates to help with mscorefonts." && \
    apt-get install -f -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
# - install some other utilitites
    echo "Installing additional utilities." && \
    apt-get install -f -y --no-install-recommends \
          python3-pip \
          libtest-pod-perl \
          curl \
          unzip \
          fontconfig \
          xz-utils && \
# - install the microsoft core fonts
    echo "Installing Microsoft core fonts." && \
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
    echo "ttf-mscorefonts-installer msttcorefonts/present-mscorefonts-eula note" | debconf-set-selections && \
    curl --output "/tmp/ttf-mscorefonts-installer.deb" "http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.7_all.deb" && \
    apt install -f -y --no-install-recommends "/tmp/ttf-mscorefonts-installer.deb" && \
    rm -f "/tmp/ttf-mscorefonts-installer.deb" && \
# - make sure to contain the EULA in our container
    echo "Adding Microsoft EULA to image." && \
    curl --output "/root/mscorefonts-eula" "http://corefonts.sourceforge.net/eula.htm" && \
# - Install some google fonts
    echo "Install Google Fonts." && \
    mkdir -p /usr/share/fonts/googlefonts && \
    curl -Lf -o /tmp/Open_Sans.zip https://fonts.google.com/download?family=Open+Sans && \
    curl -Lf -o /tmp/Montserrat.zip https://fonts.google.com/download?family=Montserrat && \
    unzip -o -d /usr/share/fonts/googlefonts/ /tmp/Open_Sans.zip && \
    unzip -o -d /usr/share/fonts/googlefonts/ /tmp/Montserrat.zip && \
    rm -rv /tmp/Open_Sans.zip /tmp/Montserrat.zip && \
# - install ghostscript as well as other tools
    echo "Installing ghostscript and other tools." && \
    apt-get install -f -y --no-install-recommends \
          ghostscript && \
    apt-get -y update && \
    apt-get -y upgrade && \
    # - clean up all temporary files
    echo "Cleaning up temporary files." && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/ssh/ssh_host_* && \
    rm -rf /var/cache/apt/archives

# - install TeX Live via install-tl
RUN echo "install TeX Live via install-tl" && \
    mkdir /tmp/texlive && \
    curl -Lf http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
        | tar zxvf - --strip-components 1 -C /tmp/texlive/ && \
    /tmp/texlive/install-tl --profile /tmp/texlive.profile -repository http://mirror.ctan.org/systems/texlive/tlnet && \
# - Install other necessary latex packages without
#   user tree and then and clean up.
    echo "Initializing user tree." && \
    tlmgr init-usertree && \
# - updating via tlmgr
    echo "Updating TeXLive via tlmgr." && \
    tlmgr --verify-repo=none update --self && \
    tlmgr --verify-repo=none update --all && \
# - calling updmap-sys
    echo "Invoking updmap-sys." && \
    updmap-sys && \
# - install Tex
    echo "Installing TeXLive packages." && \
    tlmgr --verify-repo=none install \
        adjustbox \
        awesomebox \
        babel-german \
        background \
        bidi \
        booktabs \
        blindtext \
        breakurl \
        caption \
        collectbox \
        csquotes \
        datetime \
        draftwatermark \
        ec \
        enumitem \
        environ \
        epstopdf \
        everypage \
        filehook \
        fmtcount \
        fontawesome5 \
        fontinst \
        footmisc \
        float \
        footnotebackref \
        fourier \
        framed \
        fvextra \
        grffile \
        helvetic \
        koma-script \
        lastpage \
        listings \
        letltxmacro \
        lm-math \
        ly1 \
        mdframed \
        mdwtools \
        minitoc \
        mweights \
        needspace \
        pagecolor \
        pdftexcmds \
        pgf \
        sectsty \
        setspace \
        soul \
        symbol \
        tcolorbox \
        textpos \
        times \
        titlesec \
        titling \
        ttfutils \
        ucharcat \
        ulem \
        unicode-math \
        upquote \
        xcolor \
        xkeyval \
        xetex \
        xurl \
        zapfding \
        zref && \
    (rm -rf /root/texmf || true) && \
    echo "/root/texmf deleted" && \
    echo "deleting useless packages" &&\
    cd /usr/local/texlive/texmf-dist/tex/latex/ && \
    rm -rf a0poster a4wide achemso acro* actuarial* bewerbung biochemistr* \
           bithesis bizcard bondgraph* bookshelf bubblesort carbohydrates \
           catechis cclicenses changelog cheatsheet circui* commedit comment \
           contracard course* csv* currvita* cv* dateiliste* denisbdoc \
           diabetes* dinbrief directory dirtytalk duck* duotenzor \
           dynkin-diagrams easy* elegant* elzcards emoji enigma es* \
           etaremune europasscv europecv exam* exceltex exercis* exesheet \
           ffslides fibeamer fink fithesis fixme* fjodor fla* flip* form* \
           fonttable forest g-brief gauss gcard gender genealogy* git* \
           gloss* gmdoc* HA-prosper hackthefootline halloweenmath hand* \
           harnon-cv harpoon harveyballs he-she hobby hpsdiss ifmslide \
           image-gallery invoice* interactiveworkbook isorot isotope \
           istgame iwhdp jknapltx jlabels jslectureplanner jumplines \
           kalendarium kantlipsum keystroke kix knitting* knowledge \
           komacv* labels* ladder lectures lettr* lewis logbox magaz \
           mail* makebarcode mandi mathexam mceinleger mcexam \
           medstarbeamer menu* mi-solns minorrevision minutes mla-paper \
           mnotes moderncv modernposter moderntimeline modiagram moodle \
           multiaudience mwe my* neuralnetwork newspaper nomen* papermas \
           pas-* pb-diagram permutepetiteannonce phf* philex \
           phonenumbers photo piff* pinlabel pixelart plantslabels \
           pmboxdraw pmgraph polynom* powerdot ppr-prv practicalreports \
           pressrelease probsoln productbox progress* proofread protocol \
           psbao psfrag* pst-* python qcircuit qcm qrcode qs* quantikz \
           quicktype quiz2socrative quotchap qyxf-book ran* rcs* \
           readablecv realboxes recipe* rectopma \
           reflectgraphics register reotex repeatindex rterface \
           rulercompass runcode sa-tikz sauerj schedule schemabloc \
           schooldocs scratch* scsnowman sdrt semant* seminar sem* \
           sesstime setdeck sf298 sffms shadethm shdoc shipunov \
           signchart simple* skb skdoc skeldoc skills skrapport \
           smartdiagram spectralsequences sslides studenthandouts svn* \
           swfigure swimgraf syntaxdi syntrace synttree table-fct \
           tableaux tabu talk tasks tdclock technics ted texmate \
           texpower texshade threadcol ticket ticollege todo* \
           tqft tucv tufte-latex twoup uebungsblatt uml \
           unravel upmethodology uwmslide vdmlisting venndiagram \
           verbasef verifiche versonotes vhistory vocaltract was \
           webquiz williams willowtreebook worksheet xbmks xcookybooky \
           xcpdftips xdoc xebaposter xtuthesis xwatermark xytree ya* \
           ycbook ydoc yplan zebra-goodies zed-csp zhlipsum ziffer zw* && \
    cd /tmp/ && \
# - Remove some Fonts:
    echo "Remove some Fonts." && \
    (rm -rf /usr/share/fonts/googlefonts/*wdth* || true) && \
    (rm -rf /usr/share/fonts/truetype/msttcorefonts/?erdana* || true) && \
    (rm -rf /usr/share/fonts/truetype/msttcorefonts/?rebuc* || true) && \
    (rm -rf /usr/share/fonts/truetype/msttcorefonts/?eorgia* || true) && \
    (rm -rf /usr/share/fonts/truetype/msttcorefonts/?ndale* || true) && \
    (rm -rf /usr/share/fonts/truetype/msttcorefonts/?omic* || true) && \
    (find /usr/local/texlive -type d -name "wadalab" -print0 | xargs -0 -I {} /bin/rm -rf "{}"|| true) && \
    (find /usr/local/texlive -type d -name "uhc"     -print0 | xargs -0 -I {} /bin/rm -rf "{}"|| true) && \
    (find /usr/local/texlive -type d -name "arphic"  -print0 | xargs -0 -I {} /bin/rm -rf "{}"|| true) && \
    echo "y" | updmap-sys --syncwithtrees  && \
# - update latex and font system files:
    echo "Updating LaTeX and font system files." && \
    fc-cache -fv && \
    echo "fc-cache succeeded." && \
    texhash --verbose && \
    echo "texhash completed successfully." && \
    updmap-sys && \
    echo "updmap-sys completed successfully." && \
    mktexlsr --verbose && \
    echo "mktexlsr succeeded." && \
    fmtutil-sys --quiet --missing && \
    echo "fmtutil-sys --missing completed successfully." && \
    fmtutil-sys --quiet --all > /dev/null &&\
    echo "fmtutil-sys --all completed successfully." && \
# - delete texlive sources and other potentially useless stuff
    echo "Removing potentially useless stuff from LaTeX installation." && \
    (rm -rf /usr/local/texlive/texmf-dist/source || true) && \
    (rm -rf /usr/local/texlive/texmf-dist/doc/ || true) && \
    find /usr/local/texlive -type f -name "readme*.*" -delete && \
    find /usr/local/texlive -type f -name "README*.*" -delete && \
    (rm -rf /usr/local/texlive/release-texlive.txt || true) && \
    (rm -rf /usr/local/texlive/doc.html || true) && \
    (rm -rf /usr/local/texlive/index.html || true) && \
    (rm -rf /usr/local/texlive/texmf-dist/fonts/source || true) && \
    (rm -rf /usr/local/texlive/texmf-dist/tex/latex/pst-poker || true) && \
    (rm -rf /usr/local/texlive/README || true) && \
    (rm -rf /usr/local/texlive/texmf-dist/texdoctk || true) && \
    (rm -rf /usr/local/texlive/texmf-dist/texdoc || true) && \
    echo "Removing doc and other useless things." && \
    rm -rf /usr/share/doc && \
    mkdir -p /usr/share/doc && \
    find / -name *.exe -exec rm -rv {} \; && \
    find / -name *.log -exec rm -rv {} \; && \
# - final cleanup
    echo "Performing final clean-up." && \
    rm -rf /tmp/* /var/tmp/*

# RUN as user root
# ------------------------------------------------------------------------------
# install pandoc from github
RUN echo "Install latest pandoc from beta." && \
    PANDOC_URL=$(curl -s https://api.github.com/repos/jgm/pandoc/releases/latest \
        | grep "browser_download.*pandoc-.*-linux-${TARGETARCH}.tar.gz" \
        | cut -d: -f 2,3 | tr -d '"' ) && \
    curl -Lf ${PANDOC_URL} \
        | tar zxvf - --strip-components 2 -C /usr/local/bin && \
    rm -rf /usr/local/bin/man /usr/local/bin/pandoc-citeproc && \
    pip install --upgrade pip 2>&1 |grep -v "Running pip as the" && \
    export PIP_ROOT_USER_ACTION=ignore && \
    pip install --upgrade setuptools wheel --root-user-action=ignore && \
    pip install pandoc-latex-color && \
    pip install pandoc-include && \
    pip install pandoc-latex-environment && \
    pip cache purge && \
    rm -rf ~/.cache/pip/* /tmp/* /var/tmp/* && \
    mkdir -p ${WORKDIR}

# - install the oradba LaTeX template from github and adjust the default logo
RUN echo "Install latest OraDBA Templates from GitHub." && \
    mkdir -p ${ORADBA} ${PANDOC_DATA} ${PANDOC_DATA}/templates ${PANDOC_DATA}/themes && \
    curl -Lf ${GITHUB_URL}  |tar zxv --strip-components=1 -C ${ORADBA}  && \
    rm -rf ${ORADBA}/examples ${ORADBA}/.gitignore ${ORADBA}/LICENSE ${ORADBA}/README.md  && \
    ln -sf ${ORADBA}/templates/oradba.tex ${ORADBA}/templates/oradba.latex  && \
    for i in ${ORADBA}/templates/*; do ln -sf $i ${PANDOC_DATA}/templates/$(basename $i); done  && \
    for i in ${ORADBA}/templates/oradba.*; do ln -sf $i ${PANDOC_DATA}/templates/default.${i##*.}; done  && \
    for i in ${ORADBA}/themes/*; do ln -sf $i ${PANDOC_DATA}/themes/$(basename $i); done  && \
    ln -sf ${ORADBA}/templates/oradba.pptx ${PANDOC_DATA}/reference.pptx  && \
    ln -sf ${ORADBA}/templates/oradba.docx ${PANDOC_DATA}/reference.docx

# Define /texlive as volume
VOLUME ["${WORKDIR}"]

# set workding directory
WORKDIR "${WORKDIR}"

# set the ENTRYPOINT
ENTRYPOINT ["/usr/local/bin/pandoc"]

# Define default command for pandoc
CMD ["--help"]
# --- EOF ----------------------------------------------------------------------
