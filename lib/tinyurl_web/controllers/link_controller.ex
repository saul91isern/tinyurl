defmodule TinyurlWeb.LinkController do
  use TinyurlWeb, :controller

  alias Tinyurl.Cache.LinkCache
  alias Tinyurl.Links
  alias Tinyurl.Links.Link
  alias TinyurlWeb.SwaggerDefinitions

  action_fallback TinyurlWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.link_swagger_definitions()
  end

  swagger_path :index do
    description("List of links")
    parameters do
      q(:path, :string, "Query to search by url and hash")
    end
    response(200, "OK", Schema.ref(:LinksResponse))
  end

  def index(conn, params) do
    opts = [search: Map.get(params, "q")]
    links = Links.list_links(opts)
    render(conn, "index.json", links: links)
  end

  swagger_path :create do
    description("Creates a link")
    produces("application/json")

    parameters do
      link(
        :body,
        Schema.ref(:LinkCreate),
        "Link creation attrs"
      )
    end

    response(201, "Created", Schema.ref(:LinkResponse))
    response(303, "Resource Already Persisted")
    response(400, "Client Error")
    response(422, "Unprocessable Entity")
  end

  def create(conn, %{"link" => link_params}) do
    params = Map.take(link_params, ["url"])
    url = Map.get(params, "url")

    with {:ok, nil} <- LinkCache.get_link_by_url(url),
         {:ok, %Link{} = link} <- Links.create_link(params) do
      conn
      |> put_status(:created)
      |> render("show.json", link: link)
    end
  end

  swagger_path :delete do
    description("Deletes a link")

    parameters do
      hash(:path, :string, "Hash identifying a link uniquely", required: true)
    end

    response(204, "OK")
    response(400, "Client Error")
    response(404, "Link Not Found")
  end

  def delete(conn, %{"hash" => hash}) do
    with {:ok, %Link{} = link} <- Links.get_link_by(hash: hash),
         {:ok, %Link{}} <- Links.delete_link(link) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :redirect_external do
    description("Redirects to a url given a hash")

    parameters do
      hash(:path, :string, "Hash identifying a link uniquely", required: true)
    end

    response(400, "Client Error")
    response(302, "Redirection to complete url")
    response(404, "Link Not Found")
  end

  def redirect_external(conn, %{"hash" => hash}) do
    case LinkCache.get_link_by_hash(hash) do
      {:ok, %{url: url}} when is_binary(url) -> redirect(conn, external: url)
      {:ok, nil} -> do_redirect_external(conn, hash)
      error -> error
    end
  end

  defp do_redirect_external(conn, hash) do
    with {:ok, %Link{url: url}} <-
           Links.get_link_by(hash: hash) do
      redirect(conn, external: url)
    end
  end
end
