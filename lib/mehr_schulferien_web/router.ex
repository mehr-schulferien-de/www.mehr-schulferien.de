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
    resources "/holiday_or_vacation_types", HolidayOrVacationTypeController
    resources "/periods", PeriodController
  end

  scope "/", MehrSchulferienWeb do
    pipe_through :browser

    get "/", PageController, :index

    # School vacations
    get "/ferien/:country_slug/staedte/:city_slug", CityController, :show
    get "/ferien/:country_slug/:federal_state_slug/:county_slug", CountyController, :show
    get "/ferien/:country_slug/:federal_state_slug", FederalStateController, :show

    # Misc
    get "/landkreise-und-staedte/:country_slug/:federal_state_slug", FederalStateController, :county_show

  end
end
