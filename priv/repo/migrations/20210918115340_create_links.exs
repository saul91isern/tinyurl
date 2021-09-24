defmodule Tinyurl.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table("links") do
      add :url, :string, size: 2048, null: false
      add :hash, :string, size: 8, null: false

      timestamps()
    end

    create(unique_index("links", [:hash]))
  end
end
