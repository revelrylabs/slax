defmodule Slax.Http.Behaviour do
  @typep url :: binary()
  @typep body :: {:form, [{atom(), any()}]}
  @typep headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary}
  @typep options :: Keyword.t()

  @callback post(url, body, headers, options) :: {:ok, map()} | {:error, binary() | map()}
  @callback patch(url, body, headers, options) :: {:ok, map()} | {:error, binary() | map()}
  @callback put(url, body, headers, options) :: {:ok, map()} | {:error, binary() | map()}
  @callback get(url, headers, options) :: {:ok, map()} | {:error, binary() | map()}
end
