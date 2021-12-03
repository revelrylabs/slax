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

# Compile app
RUN mix do compile, release

#
# END BUILDER
#

FROM debian:buster-slim

RUN apt-get -qq update
RUN apt-get -qq install -y locales locales-all openssl

# Set LOCALE to UTF8
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

ENV MIX_ENV="prod" PORT="5000"

# Exposes this port from the docker container to the host machine
EXPOSE 5000

WORKDIR /app
COPY --from=builder /opt/app/_build/prod/rel/slax ./

# The command to run when this image starts up
CMD ["./bin/slax", "start"]
