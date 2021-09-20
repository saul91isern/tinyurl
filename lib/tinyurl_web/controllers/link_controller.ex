defmodule TinyurlWeb.LinkController do
  use TinyurlWeb, :controller

  alias Tinyurl.Cache.LinkCache
  alias Tinyurl.Links
  alias Tinyurl.Links.Link

  action_fallback TinyurlWeb.FallbackController

  def index(conn, _params) do
    links = Links.list_links()
    render(conn, "index.json", links: links)
  end

  def create(conn, %{"link" => link_params}) do
    url = Map.get(link_params, "url")

    with {:ok, nil} <- LinkCache.get_link_by_url(url),
         {:ok, %Link{} = link} <- Links.create_link(link_params) do
      conn
      |> put_status(:created)
      |> render("show.json", link: link)
    end
  end

  def delete(conn, %{"hash" => hash}) do
    with %Link{} = link <- Links.get_link_by(hash: hash),
         {:ok, %Link{}} <- Links.delete_link(link) do
      send_resp(conn, :no_content, "")
    end
  end

  def redirect_external(conn, %{"hash" => hash}) do
    case LinkCache.get_link_by_hash(hash) do
      {:ok, %{url: url}} when is_binary(url) -> redirect(conn, external: url)
      {:ok, nil} -> redirect_external(conn, hash)
    end
  end

  def redirect_external(conn, hash) do
    with {:ok, %Link{url: url}} <-
           Links.get_link_by(hash: hash) do
      redirect(conn, external: url)
    end
  end
end
