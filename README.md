Master status: ![TravisCI Build Status](https://travis-ci.org/revelrylabs/slax.svg)

# Slax

A Phoenix app that supports the following slash commands from Slack:

## Install

```
git clone https://github.com/revelrylabs/slax
mix deps.get
mix ecto.create && mix ecto.migrate
mix phx.server
```

## Configuration

`.env.sample` is a template for the required environment variables. Copy it to .env:

```
cp .env.sample .env
```

and fill in with your actual credentials and configuration.

Before running the app, you can do:

```
source .env
```

to ensure the variables are set properly.

## Usage / Commands

All commands provide usage details when executing them without any parameters.

### /auth

This command will authenticate the Slack user with different services so that actions performed will be attributed to that user. This currently supports the following services:

* Github

Example: `/auth github`

### /issue

Create an issue on any Github repository that the authenticated user has access to. If the user is not authenticated, he or she will be directed to use `/auth github` to authenticate. If a new line is present in the message, everything after it will be considered part of the body. After creating the issue it will give you a link to it.

Usage: `/issue <org/repo> <title> [\nbody]`

Example: `/issue revelrylabs/slax New Issue!`

<img src="http://dropit.atda.club/Screen-Shot-2016-07-05-13-44-34.png" width="350">

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/revelrylabs/slax. Check out [CONTRIBUTING.md](https://github.com/revelrylabs/slax/blob/master/CONTRIBUTING.md) for more info.

Everyone is welcome to participate in the project. We expect contributors to
adhere the Contributor Covenant Code of Conduct (see [CODE_OF_CONDUCT.md](https://github.com/revelrylabs/slax/blob/master/CODE_OF_CONDUCT.md)).
