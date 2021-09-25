defmodule Tinyurl.LinksTest do
  use Tinyurl.DataCase

  alias Tinyurl.Cache.LinkCache
  alias Tinyurl.Hasher
  alias Tinyurl.Links
  alias Tinyurl.Links.Link
  alias Tinyurl.Repo

  setup_all do
    start_supervised!(Tinyurl.Cache.LinkCache)
    :ok
  end

  setup do
    {:ok, seed} = LinkCache.get_seed()
    on_exit(fn -> CacheHelpers.clean() end)
    [seed: seed]
  end

  describe "list_links/0" do
    test "returns all links" do
      link = insert(:link)
      assert Links.list_links() == [link]
    end

    test "search over url or hash if quey specified" do
      link = %{hash: hash, url: url} = insert(:link)
      assert Links.list_links(search: String.slice(hash, 0, 2)) == [link]
      assert Links.list_links(search: String.slice(url, 0, 2)) == [link]
      assert Links.list_links(search: "made up") == []
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

    test "returns not_found if link does not exist" do
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

    test "raises error if hash repeated" do
      %{hash: hash} = insert(:link)
      changeset = Link.changeset(%Link{}, %{url: "http://made/up", hash: hash})

      assert {:error,
              %{
                errors: [
                  hash:
                    {"has already been taken",
                     [constraint: :unique, constraint_name: "links_hash_index"]}
                ]
              }} = Repo.insert(changeset)
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

  describe "duplicated_links" do
    test "get duplicated links by url" do
      repeated_url = "https://foo/bar"
      repeated = Enum.map(1..5, fn _ -> insert(:link, url: repeated_url) end)
      insert(:link, url: "https://bar/baz")
      insert(:link, url: "https://xyz/xyz")
      ids = Enum.map(repeated, & &1.id)
      assert [%{url: ^repeated_url, links: links}] = Links.duplicated_links()
      assert ids == Enum.map(links, & &1["id"])
    end
  end

  describe "delete_all/1" do
    test "deletes all links given a set of ids" do
      links = Enum.map(1..5, fn _ -> insert(:link) end)
      ids = Enum.map(links, & &1.id)
      assert {5, _} = Links.delete_all(ids)

      for id <- ids do
        assert_raise Ecto.NoResultsError, fn -> Links.get_link!(id) end
      end
    end

    test "does not delete anything under empty id list" do
      links = Enum.map(1..5, fn _ -> insert(:link) end)
      ids = Enum.map(links, & &1.id)
      assert {0, _} = Links.delete_all([])

      for id <- ids do
        assert %Link{id: ^id} = Links.get_link!(id)
      end
    end
  end
end
