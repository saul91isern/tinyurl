defmodule Tinyurl.Links.Link do
  use Ecto.Schema
  import Ecto.Changeset

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
  end
end
