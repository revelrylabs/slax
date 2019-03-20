# Set the Docker image you want to base your image off.
FROM erlang:21.2

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.8.1" \
  LANG=C.UTF-8

RUN set -xe \
  && ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
  && ELIXIR_DOWNLOAD_SHA256="de8c636ea999392496ccd9a204ccccbc8cb7f417d948fd12692cda2bd02d9822" \
  && curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
  && echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/local/src/elixir \
  && tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
  && rm elixir-src.tar.gz \
  && cd /usr/local/src/elixir \
  && make install clean

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
CMD ["_build/prod/rel/slax/bin/slax", "foreground"]
