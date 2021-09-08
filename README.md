# PeerBot


## Project Setup

- You will need an ngrok proxy by running `ngrok http 4000`. It's recommended to have a paid ngrok account so you can keep the same domain everytime you run the app.
- Create a [new slack app](https://api.slack.com/apps?new_app=1) select "`From an app manifest`" and copy and paste an edited version of the `slack.config.yaml` making sure your ngrok domain is correct.
- Create a `dev.secret.exs` file in your `/config` directory and add the `client_id` and `client_secret` from your newly created slack app:
  ```elixir
  use Mix.Config

  config :slax, Slax.Slack,
    client_id: "your client id goes here",
    client_secret: "your client secret goes here"
  ```
- Then the regular stuff, `npm i --prefix assets; mix ecto.setup; mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.  If you do not have a paid ngrok account, make sure you replace your current slack app if you start up a new ngrok proxy. 


## Staging Environment

URL: https://slax-web.fly.dev
Slack Workspace: https://join.slack.com/t/slaxtestspace/shared_invite/zt-su1rj32q-B0TIykcqNMHiKswGGX4KhA
