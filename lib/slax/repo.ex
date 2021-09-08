defmodule Slax.Repo do
  use Ecto.Repo,
    otp_app: :slax,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
