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

The [/bin/setup](https://github.com/revelrylabs/slax/blob/master/bin/setup) script should add a `config/dev.secret.exs` file. Use this to put secrets into.
[/rel/config/prod_runtime_config.exs](https://github.com/revelrylabs/slax/blob/master/rel/config/prod_runtime_config.exs) is a good example of what secrets are needed as that file is used to setup secrets in produciton.

You will need to create a GitHub OAuth app in order to use the GitHub functionality, including authentication.

### Create Github OAuth App
- Go to https://github.com/settings/developers
- Click "New Oauth App"
- Fill in the following values:
  - Application Name: <your_app_name>
  - Homepage URL: Your app's URL (For development: http://localhost:4000 works)
  - Authorization callback URL: (For development: http://localhost:4000/auth/github_callback works)
- Click "Register Application"
- Take the `Client ID` and `Client Secret` values and add them and put them in the configuration block for `Slax.Github` in your `dev.secret.exs` file

```elixir
config :slax, Slax.Github,
  api_url: "https://api.github.com",
  oauth_url: "https://github.com/login/oauth",
  client_id: "<my_client_id>",
  client_secret: "<my_client_secret>",
  org_name: "<my_org_name>",
  org_teams: ["<my_org_team>"]
```
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
