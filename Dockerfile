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

RUN --mount=type=secret,id=bitbucket_password \
    --mount=type=secret,id=gh_pat \
    sh -c 'echo "BITBUCKET_USER=$BITBUCKET_USER" > .Renviron && \
           echo "BITBUCKET_PASSWORD=$(cat /run/secrets/bitbucket_password)" >> .Renviron && \
           echo "GITHUB_PAT=$(cat /run/secrets/gh_pat)" >> .Renviron'

RUN Rscript -e "install.packages('renv')"
RUN Rscript -e "renv::install()"
RUN  rm .Renviron
