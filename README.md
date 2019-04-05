![TravisCI Build Status](https://travis-ci.org/revelrylabs/slax.svg)
[![Coverage Status](https://coveralls.io/repos/github/revelrylabs/slax/badge.svg?branch=master)](https://coveralls.io/github/revelrylabs/slax?branch=master)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Slax

A Phoenix app that supports the following slash commands from Slack:

## Install

```
git clone https://github.com/revelrylabs/slax
./bin/setup
./bin/server
```

## Configuration

The `./bin/setup` script should add a `config/dev.secret.exs` file. Use this to put secrets into.
[/rel/config/prod_runtime_config.exs](https://github.com/revelrylabs/slax/blob/master/rel/config/prod_runtime_config.exs) is a good example of what secrets are needed as that file is used to setup secrets in produciton.

## Usage / Commands

All commands provide usage details when executing them without any parameters.

### /auth

This command will authenticate the Slack user with different services so that actions performed will be attributed to that user. This currently supports the following services:

- Github

Example: `/auth github`

### /issue

Create an issue on any Github repository that the authenticated user has access to. If the user is not authenticated, he or she will be directed to use `/auth github` to authenticate. If a new line is present in the message, everything after it will be considered part of the body. After creating the issue it will give you a link to it.

Usage: `/issue <org/repo> <title> [\nbody]`

Example: `/issue revelrylabs/slax New Issue!`

<img src="http://dropit.atda.club/Screen-Shot-2016-07-05-13-44-34.png" width="350">

### /project

#### new

Creates a new repo in github, runs reusable stories, sets up webhooks, and creates slack channel if it doesn't exist.

Usage: `/project new <project_name>`

Example: `/project new taco`

Creates repo in the default organization

#### add-reusable-stories

runs reusable stories in the given repo

Usage: `/project add-reusable-stories <repo>`

Example: `/project add-reusable-stories taco`

Looks for repo in the default organization

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/revelrylabs/slax. Check out [CONTRIBUTING.md](https://github.com/revelrylabs/slax/blob/master/CONTRIBUTING.md) for more info.

Everyone is welcome to participate in the project. We expect contributors to
adhere the Contributor Covenant Code of Conduct (see [CODE_OF_CONDUCT.md](https://github.com/revelrylabs/slax/blob/master/CODE_OF_CONDUCT.md)).
