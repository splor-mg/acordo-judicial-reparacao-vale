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

RUN Rscript -e "install.packages('renv')"
RUN Rscript -e "options(renv.config.bitbucket.host = 'https://bitbucket.org')"
RUN Rscript -e "options(renv.config.bitbucket.auth_user = Sys.getenv('BITBUCKET_USER'))"
RUN Rscript -e "options(renv.config.bitbucket.password = Sys.getenv('BITBUCKET_PASSWORD'))"
