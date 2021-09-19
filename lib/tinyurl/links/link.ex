defmodule Tinyurl.Links.Link do
  use Ecto.Schema
  import Ecto.Changeset

  @hash_size 8
  @url_size 2048

  schema "links" do
    field :hash, :string
    field :url, EctoURL

    timestamps()
  end

  @doc false
  def changeset(link, attrs) do
    link
    |> cast(attrs, [:url, :hash])
    |> validate_required([:url, :hash])
    |> validate_length(:hash, max: @hash_size)
    |> validate_length(:url, max: @url_size)
    |> unique_constraint(:hash)
    |> validate_change(:url, &valid_url?/2)
  end

  defp valid_url?(:url, url) do
    parsed = URI.parse(url)

    case parsed do
      %URI{scheme: scheme} when is_nil(scheme) or scheme == "" ->
        [url: {"expected schema to be informed", [validation: :format]}]

      %URI{host: host} when is_nil(host) or host == "" ->
        [url: {"expected host to be informed", [validation: :format]}]

      _uri ->
        []
    end
  end
end
