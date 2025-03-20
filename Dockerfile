# --- Builder Stage ---
  FROM rocker/r-ver:4.3.3 AS builder

  WORKDIR /project

  # Install Python and required packages
  RUN /rocker_scripts/install_python.sh
  RUN export DEBIAN_FRONTEND=noninteractive && \
      apt-get update && apt-get install -y git libcurl4-openssl-dev libssl-dev libsodium-dev jq
  RUN echo 'alias python=python3' >> /etc/bash.bashrc

  # Copy your application files
  COPY requirements.txt .
  COPY DESCRIPTION .

  # Install Python dependencies
  RUN python3 -m pip install --upgrade pip setuptools wheel
  RUN python3 -m pip install -r requirements.txt

  # Pass non-sensitive argument
  ARG BITBUCKET_USER

  # Use BuildKit secrets for sensitive data.
  # Note: Ensure BuildKit is enabled and that you pass these secrets from your CI/CD.
  RUN --mount=type=secret,id=bitbucket_password \
      --mount=type=secret,id=gh_pat \
      sh -c 'echo "BITBUCKET_USER=$BITBUCKET_USER" > .Renviron && \
             echo "BITBUCKET_PASSWORD=$(cat /run/secrets/bitbucket_password)" >> .Renviron && \
             echo "GITHUB_PAT=$(cat /run/secrets/gh_pat)" >> .Renviron'

  # Run your R commands that need the secrets
  RUN Rscript -e "install.packages('renv')"
  RUN Rscript -e "renv::install()"

  # Remove the .Renviron file to clean up the secrets from this stage
  RUN rm .Renviron

  # --- Final Stage ---
  FROM rocker/r-ver:4.3.3 AS final

  WORKDIR /project

  # Copy only the necessary files from the builder stage (which no longer include secrets)
  COPY --from=builder /project /project
