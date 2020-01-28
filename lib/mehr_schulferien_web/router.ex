defmodule MehrSchulferienWeb.Router do
  use MehrSchulferienWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/admin", MehrSchulferienWeb do
    pipe_through :browser

    # Maps
    resources "/locations", LocationController
    resources "/zip_codes", ZipCodeController
    resources "/zip_code_mappings", ZipCodeMappingController

    # Calendars
    resources "/religions", ReligionController
  end

  scope "/", MehrSchulferienWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", MehrSchulferienWeb do
  #   pipe_through :api
  # end
end
