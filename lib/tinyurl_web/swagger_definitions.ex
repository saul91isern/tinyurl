defmodule TinyurlWeb.SwaggerDefinitions do
  @moduledoc """
   Swagger definitions used by controllers
  """
  import PhoenixSwagger

  def link_swagger_definitions do
    %{
      Link:
        swagger_schema do
          title("Link")
          description("Link represented by a url and its hash")

          properties do
            url(:string, "Complete url", required: true)
            hash(:string, "Shortened hash representing a url", required: true)
          end
        end,
      LinksResponse:
        swagger_schema do
          title("Links")
          description("List of shortened links")

          properties do
            data(Schema.ref(:LinksResponseData))
          end
        end,
      LinksResponseData:
        swagger_schema do
          type(:array)
          items(Schema.ref(:Link))
        end,
      LinkResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Link))
          end
        end,
      LinkCreate:
        swagger_schema do
          title("Link creation params")
          description("Url to shorten")

          properties do
            url(:string, "Complete url to shorten", required: true)
          end
        end
    }
  end
end
