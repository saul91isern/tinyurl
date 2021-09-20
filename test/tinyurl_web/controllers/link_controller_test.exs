defmodule TinyurlWeb.LinkControllerTest do
  use TinyurlWeb.ConnCase

  alias Tinyurl.Cache.LinkCache
  alias Tinyurl.Hasher
  alias Tinyurl.Links

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all links", %{conn: conn} do
      %{url: url, hash: hash} = insert(:link)
      conn = get(conn, Routes.link_path(conn, :index))
      assert [%{"url" => ^url, "hash" => ^hash}] = json_response(conn, 200)["data"]
    end
  end

  describe "create link" do
    setup do
      link = create_link()

      on_exit(fn ->
        CacheHelpers.clean()
      end)

      {:ok, seed} = LinkCache.get_seed()

      [link: link, seed: seed]
    end

    test "renders link when data is valid", %{conn: conn, seed: seed} do
      url = "http://valid/url"
      hash = Hasher.encode(seed + 1)
      conn = post(conn, Routes.link_path(conn, :create), link: %{"url" => url})
      assert %{"url" => ^url, "hash" => ^hash} = json_response(conn, 201)["data"]

      on_exit(fn ->
        LinkCache.delete(%{url: url, hash: hash})
      end)
    end

    test "returns 303 if resource is already cached", %{conn: conn, link: %{url: url}} do
      conn = post(conn, Routes.link_path(conn, :create), link: %{"url" => url})
      assert %{"errors" => %{"detail" => "See Other"}} = json_response(conn, 303)
    end

    test "renders errors when no url provided", %{conn: conn} do
      conn = post(conn, Routes.link_path(conn, :create), link: %{"url" => nil})
      assert %{"url" => ["can't be blank"]} = json_response(conn, 422)["errors"]
    end

    test "renders errors when url is invalid", %{conn: conn} do
      conn = post(conn, Routes.link_path(conn, :create), link: %{"url" => "domain.net"})
      assert %{"url" => ["expected schema to be informed"]} = json_response(conn, 422)["errors"]

      conn = post(conn, Routes.link_path(conn, :create), link: %{"url" => "http://"})
      assert %{"url" => ["expected host to be informed"]} = json_response(conn, 422)["errors"]
    end
  end

  describe "redirect external" do
    setup do
      link = create_link()

      on_exit(fn ->
        CacheHelpers.clean()
      end)

      [link: link]
    end

    test "redirects to url on hash redirect", %{conn: conn, link: %{hash: hash, url: url}} do
      conn = get(conn, Routes.link_path(conn, :redirect_external, hash))
      response = response(conn, 302)
      assert String.contains?(response, url)
    end

    test "returns 404 if link is not found", %{conn: conn} do
      conn = get(conn, Routes.link_path(conn, :redirect_external, "xyz"))
      assert %{"errors" => %{"detail" => "Not Found"}} = json_response(conn, 404)
    end
  end

  defp create_link do
    params = string_params_for(:link) |> Map.take(["url"])
    {:ok, link} = Links.create_link(params)

    on_exit(fn -> LinkCache.delete(link) end)

    link
  end
end
