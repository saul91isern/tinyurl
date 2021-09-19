defmodule Tinyurl.LinksTest do
  use Tinyurl.DataCase

  alias Redis
  alias Tinyurl.Cache.LinkCache
  alias Tinyurl.Hasher
  alias Tinyurl.Links
  alias Tinyurl.Links.Link

  setup do
    {:ok, seed} = LinkCache.get_seed()
    on_exit(fn -> Redix.command(:redix, ["DEL", "seed"]) end)
    [seed: seed]
  end

  describe "list_links/0" do
    test "returns all links" do
      link = insert(:link)
      assert Links.list_links() == [link]
    end
  end

  describe "get_link!/1" do
    test "returns the link with given id" do
      link = insert(:link)
      assert Links.get_link!(link.id) == link
    end

    test "raises `Ecto.NoResultsError` if link does not exist" do
      id = System.unique_integer([:positive])
      assert_raise Ecto.NoResultsError, fn -> Links.get_link!(id) end
    end
  end

  describe "get_link_by/1" do
    test "returns the link with given params" do
      link = %{url: url, hash: hash} = insert(:link)
      assert Links.get_link_by(url: url) == {:ok, link}
      assert Links.get_link_by(hash: hash) == {:ok, link}
      assert Links.get_link_by(url: url, hash: hash) == {:ok, link}
    end

    test "raises nil` if link does not exist" do
      insert(:link)
      assert {:error, :not_found} = Links.get_link_by(url: "made_up")
    end
  end

  describe "create_link/1" do
    test "creates a link with valid params", %{seed: seed} do
      hash = Hasher.encode(seed + 1)
      params = %{"url" => url} = string_params_for(:link) |> Map.take(["url"])
      assert {:ok, %Link{hash: ^hash, url: ^url} = link} = Links.create_link(params)
      
      on_exit(fn -> LinkCache.delete(link) end)
    end

    test "raises error if url not provided" do
      assert {:error, %Ecto.Changeset{errors: [url: {"can't be blank", [validation: :required]}]}} =
               Links.create_link(%{})
    end
  end

  describe "delete_link/1" do
    test "deletes link" do
      link = insert(:link)
      assert {:ok, %Link{id: id}} = Links.delete_link(link)
      assert_raise Ecto.NoResultsError, fn -> Links.get_link!(id) end
    end
  end
end
