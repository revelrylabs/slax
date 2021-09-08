defmodule SlaxWeb.Normalize do
  @moduledoc """
  Normalize user input with schemaless changesets

  Example usage:
  ```
    input_schema = [
      email: [:string, required: true],
      password: [:string, required: true]
    ]

    case normalize(params, input_schema) do
      {:ok, normalized_input} ->
        ...
      {:error, changeset} ->
        ...
    end
  ```
  """
  import Ecto.Changeset

  @spec normalize(params :: map(), input_schema :: list()) :: map() | Ecto.Changeset.t()
  def normalize(params, input_schema) do
    {%{}, to_types(input_schema)}
    |> cast(params, cast_keys(input_schema))
    |> validate_required(required_keys(input_schema))
    |> apply_changes()
  end

  defp cast_keys(input_schema) do
    Keyword.keys(input_schema)
  end

  defp required_keys(input_schema) do
    required =
      Enum.filter(input_schema, fn {_key, [_type | opts]} ->
        Enum.find(opts, fn {key, value} ->
          key === :required && value
        end)
      end)

    Keyword.keys(required)
  end

  defp to_types(input_schema) do
    input_schema
    |> Enum.map(fn {key, [value | _]} -> {key, value} end)
    |> Enum.into(%{})
  end
end
