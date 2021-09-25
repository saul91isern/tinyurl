defmodule TinyurlWeb.PingController do
  use TinyurlWeb, :controller

  action_fallback TinyurlWeb.FallbackController

  def ping(conn, _params) do
    send_resp(conn, 200, "pong")
  end
end
