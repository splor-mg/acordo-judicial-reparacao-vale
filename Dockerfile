FROM rocker/r-ver:4.3.3


WORKDIR /project

RUN /rocker_scripts/install_python.sh

RUN export DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y git libcurl4-openssl-dev libssl-dev libsodium-dev jq


RUN echo 'alias python=python3' >> /etc/bash.bashrc

COPY requirements.txt .
COPY DESCRIPTION .

RUN python3 -m pip install --upgrade pip setuptools wheel
RUN python3 -m pip install -r requirements.txt

ARG BITBUCKET_USER
ARG BITBUCKET_PASSWORD
ARG GH_PAT

RUN echo "BITBUCKET_USER=$BITBUCKET_USER" > .Renviron &&\
    echo "BITBUCKET_PASSWORD=$BITBUCKET_PASSWORD" >> .Renviron &&\
    echo "GITHUB_PAT=$GH_PAT" >> .Renviron

RUN Rscript -e "install.packages('renv')"
RUN Rscript -e "renv::install()"
RUN  rm .Renviron
