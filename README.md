# Pandoc Docker Images
Docker scripts to build an image to run the universal document converter [pandoc](https://pandoc.org) including support to convert PDF files. The image includes a reduced [texlive 2018](https://www.tug.org/texlive/) installation to support simple PDF transformations. Additional texlive packages have to be installed be extending this images. 

## Run

The pre build image is availabe via [Dockerhub](https://hub.docker.com/r/oehrlis/pandoc/). The installation and use is straightforward. Install [Docker](https://www.docker.com/get-started) and pull the image.

```bash
docker pull oehrlis/pandoc
```

Either you copy the files into the container, which is obviously not really handy, or you mount your local document folder as volume and run it.

```bash
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc <OPTIONS>
```

Conversion of the sample Markdown file into a PDF using the default LaTeX template.

```bash
cd sample
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc sample.md \
    -o sample.pdf --toc -N --listings
```

Conversion of the sample Markdown file into a PDF using the Trivadis LaTeX template.

```bash
cd sample
docker run --rm -v $PWD:/workdir:z oehrlis/pandoc sample.md \
    -o sample_trivadis.pdf --template trivadis --toc -N --listings
```

Alternatively you can open a shell in the container and use the miscellanies pandoc and tex tools interactively.

```bash
docker run -it --rm -v $PWD:/workdir:z --entrypoint bash oehrlis/pandoc
```

## Build and add new packages

If you plan to alter or extend this Docker image you could get the corresonding files from [GitHub](https://github.com/oehrlis/docker-pandoc) and build the image manually.

```bash
git clone git@github.com:oehrlis/docker-pandoc.git
$ cd docker-pandoc
$ docker build -t oehrlis/pandoc .
```

Optionally you can add additional texlive package to the `tlmgr` command in the Dockerfile.

## Issues

Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/oehrlis/docker-pandoc/issues)
* [submit new issue](https://github.com/oehrlis/docker-pandoc/issues/new)

## References

* [pandoc](https://pandoc.org)
* [texlive 2018](https://www.tug.org/texlive/)