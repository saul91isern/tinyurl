defmodule TinyurlWeb.Router do
  use TinyurlWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/swagger" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :tinyurl, swagger_file: "swagger.json")
  end

  scope "/api", TinyurlWeb do
    pipe_through :api
    get "/ping", PingController, :ping
    resources "/links", LinkController, only: [:create, :delete, :index], param: "hash"
  end

  scope "/", TinyurlWeb do
    pipe_through  :api
    get "/:hash", LinkController, :redirect_external
  end

  # Enables LiveDashboard only for development
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/", TinyurlWeb do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: TinyurlWeb.Telemetry
    end
  end

  def swagger_info do
    %{
      schemes: ["http", "https"],
      info: %{
        version: Application.spec(:tinyurl, :vsn),
        title: "Tiny Url Service"
      }
    }
  end
end
