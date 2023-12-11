![TravisCI Build Status](https://travis-ci.org/revelrylabs/slax.svg)
[![Coverage Status](https://opencov.prod.revelry.net/projects/4/badge.svg)](https://opencov.prod.revelry.net/projects/4)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Slax

A Phoenix app that supports the following slash commands from Slack:

## Install

```
git clone https://github.com/revelrylabs/slax
./bin/setup
```

## Configuration

The [/bin/setup](https://github.com/revelrylabs/slax/blob/master/bin/setup) script should add a `config/dev.secret.exs` file. Use this to put secrets into.
[/config/runtime.exs](https://github.com/revelrylabs/slax/blob/master/config/runtime.exs) is a good example of what secrets are needed as that file is used to setup secrets in produciton. (only the configs listed in the following sections are needed for the currently used functionality)

You will need to create a GitHub OAuth app in order to use the GitHub functionality, including authentication, and a Slack workspace and app.

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

### Create Slack App
- Go to https://slack.com/get-started#/createnew and create a workspace for testing
- Go to https://api.slack.com/apps
- Click "Create New App" and select "From an app manifest"
- Select your new Slack workspace
- Copy slack-manifest.yml into the field and create the App
- Click "Install to Workspace" and allow it in your workspace
- Generate an app-level token with the "connections:write" scope and copy the generated token into `config/dev.secret.exs`
- Go to the `Install App` menu and copy the Bot User OAuth Token into `config/dev.secret.exs`

```elixir
config :slax, Slax.Slack,
  api_url: "https://slack.com/api",
  api_token: "<bot_user_oauth_token>",
  channel_name: "<default_post_channel>",
  app_token: "<app_level_token>"
```

## Usage / Commands

```./bin/server```
All commands provide usage details when executing them without any parameters.
> **_NOTE:_** Issue / PR lookup and pokerbot require a fine grained access token be setup for the specified repos with the `/token` command

### /token
This is a slack shortcut that is an interactive series of modals to setup project repo connections in the database as well as store fine grained access tokens to enable issue lookup and poker functionality. **This is necessary** for proper functionality of Issue/PR lookup and Poker.

The first modal you see lets you select a Repo and attach an access token and expiration date to it.
The second modal is accessed by clicking Create Repo and lets you either select or create a new Project and attach a Repo to the Project

To generate a fine grained access token go to https://github.com/settings/tokens?type=beta and fill out the form. Check `Only Select Repositories` and select the desired repo(s). Under Repository Permissions, give at least Read and write to `Issues` and Read only to `Pull Requests`. Extra setup video for Github Access tokens with different permissions: https://www.loom.com/share/43993db839d14fbd86a9ce344e17b7fb
> **_NOTE:_**  For third party organizations, fine grained access tokens must be enabled.

### /slax disable
This is a slack shortcut that is an interactive modal to disable Slax Issue/PR lookup in a specific channel.

### /slax enable
This is a slack shortcut that is an interactive modal to enable Slax Issue/PR lookup in a specific channel.

### Issue & PR lookup
With the websocket connection slax parses every message for the specified patterns corresponding to an issue `org/repo#1` `repo#1` or a PR `org/repo$1` `repo$1`.

### /poker
This command is the interaction point for the poker feature and when just typing `/poker` it will respond with a help message on how to use it.

### _The following commands have not been tested or used in a while_

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
