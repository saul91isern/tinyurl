defmodule EctoURL do
  @moduledoc """
  Ecto type representing links in database
  """
  use Ecto.Type
  def type, do: :string

  # Cast strings into a utf8 safe url
  def cast(uri) when is_binary(uri) do
    {:ok, URI.decode(uri)}
  end

  # Everything else is a failure though
  def cast(_), do: :error

  # Load string url
  def load(data) when is_binary(data) do
    {:ok, data}
  end

  # When dumping data to the database, we *expect* a valid string
  def dump(url) when is_binary(url), do: {:ok, url}
  def dump(_), do: :error
end
