# Set the Docker image you want to base your image off.
FROM hexpm/elixir:1.12.3-erlang-24.1.7-debian-buster-20210902 as builder

# Install other stable dependencies that don't change often
RUN apt-get update && \
  apt-get install -y --no-install-recommends apt-utils postgresql-client nodejs

WORKDIR /opt/app

# Install and compile project dependencies
# We do this before all other files to make container build faster
# when configuration and dependencies are not changed
COPY mix.* ./
COPY config/* ./config/

ENV MIX_ENV prod

RUN mix do local.rebar --force, local.hex --force, deps.get --only prod, deps.compile

# Add the files to the image
COPY . .

ENV PORT 5000

# Compile app
RUN mix do compile, release

# Exposes this port from the docker container to the host machine
EXPOSE 5000

# The command to run when this image starts up
# CMD ["_build/prod/rel/slax/bin/slax", "start"]
