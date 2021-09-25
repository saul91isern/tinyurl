defmodule Tinyurl.Cache.LinkCacheTest do
  use Tinyurl.DataCase

  alias Tinyurl.Cache.LinkCache
  alias Tinyurl.Links
  alias Tinyurl.RedisHelper

  setup_all do
    start_supervised!(Tinyurl.Cache.LinkCache)
    :ok
  end

  setup do
    CacheHelpers.clean()

    on_exit(fn ->
      CacheHelpers.clean()
    end)

    link = Map.take(build(:link), [:url, :hash])
    {:ok, _} = RedisHelper.put_link(link)

    [link: link]
  end

  describe "get_seed/1" do
    test "gets an inremental seed to generate a new hash" do
      {:ok, init} = LinkCache.get_seed()
      last = init + 10

      for i <- init..last do
        {:ok, seed} = LinkCache.get_seed()
        assert seed == i + 1
      end
    end
  end

  describe "get_link_by_hash/1" do
    test "gets {:ok, link} by given hash", %{link: link = %{hash: hash}} do
      assert {:ok, ^link} = LinkCache.get_link_by_hash(hash)
    end

    test "gets {:ok, nil} when link does not exist" do
      assert {:ok, nil} = LinkCache.get_link_by_hash("bar")
    end
  end

  describe "get_link_by_url/1" do
    test "gets {:ok, link} by given url", %{link: link = %{url: url}} do
      assert {:ok, ^link} = LinkCache.get_link_by_url(url)
    end

    test "gets {:ok, nil} when link does not exist" do
      assert {:ok, nil} = LinkCache.get_link_by_hash("http://domain/path")
    end
  end

  describe "refresh/1" do
    test "puts link in cache" do
      hash = "madeuphash"
      link = %{hash: hash, url: "http://madeup/url"}
      assert :ok == LinkCache.refresh(link)
      assert {:ok, ^link} = LinkCache.get_link_by_hash(hash)
    end
  end

  describe "delete/1" do
    test "deletes link from cache", %{link: %{hash: hash} = link} do
      assert {:ok, ^link} = LinkCache.get_link_by_hash(hash)
      assert :ok == LinkCache.delete(link)
      assert {:ok, nil} = LinkCache.get_link_by_hash(hash)
    end
  end

  describe "reset_seed/1" do
    test "resets seed by max id in cache" do
      insert(:link)
      id = Links.max_id()
      assert {:ok, "OK"} = LinkCache.reset_seed()
      assert {:ok, seed} = LinkCache.get_seed()
      assert seed == id + 1
      assert {:ok, seed} = LinkCache.get_seed()
      assert seed == id + 2
    end
  end

  describe "migrate/1" do
    test "migrates links, deletes duplicates, and keeps them up to date" do
      repeated_url = "https://foo/bar"
      repeated = Enum.map(1..5, fn _ -> insert(:link, url: repeated_url) end)
      l6 = insert(:link, url: "https://bar/baz")
      l7 = insert(:link, url: "https://xyz/xyz")
      all_links = repeated ++ [l6, l7]

      for link <- all_links do
        assert {:ok, _} = RedisHelper.put_link(link)
      end

      LinkCache.migrate()

      assert {:ok, %{url: ^repeated_url, hash: hash}} = LinkCache.get_link_by_url(repeated_url)
      assert {:ok, %{url: ^repeated_url, hash: ^hash}} = LinkCache.get_link_by_hash(hash)
      {:ok, %{id: id}} = Links.get_link_by(hash: hash)
      assert [] = Links.duplicated_links()

      repeated_ids =
        repeated
        |> Enum.map(& &1.id)
        |> List.delete(id)

      for id <- repeated_ids do
        assert_raise Ecto.NoResultsError, fn -> Links.get_link!(id) end
      end
    end
  end
end
