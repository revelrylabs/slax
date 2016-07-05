# Slax

A Phoenix app that supports the following slash commands from Slack:

## Commands

All commands provide usage details when executing them without any parameters.

### /auth

This command will authenticate the Slack user with different services so that actions performed will be attributed to that user. This currently supports the following services:

* Github

Example: `/auth github`

### /issue

Create an issue on any Github repository that the authenticated user has access to. If the user is not authenticated, he or she will be directed to use `/auth github` to authenticate. If a new line is present in the message, everything after it will be considered part of the body. After creating the issue it will give you a link to it.

Usage: `/issue \<org/repo\> \<title\> [\nbody]`

Example: `/issue revelrylabs/slax New Issue!`

<img src="http://dropit.atda.club/Screen-Shot-2016-07-05-13-44-34.png" width="350">

## Running this application locally

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Start Phoenix endpoint with `mix phoenix.server`

