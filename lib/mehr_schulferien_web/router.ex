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

  scope "/", MehrSchulferienWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    # Locations
    #
    resources "/schools", SchoolController, only: [:show]
    get "/schools/:school_id/:starts_on/:ends_on", SchoolController, :show
    get "/schools/:school_id/:year", SchoolController, :show

    resources "/cities", CityController, only: [:show]
    get "/cities/:city_id/:starts_on/:ends_on", CityController, :show
    get "/cities/:city_id/:year", CityController, :show

    resources "/federal_states", FederalStateController, only: [:show]
    get "/federal_states/:federal_state_id/:starts_on/:ends_on", FederalStateController, :show
    get "/federal_states/:federal_state_id/:year", FederalStateController, :show

    resources "/countries", CountryController, only: [:show]
  end

  scope "/admin", MehrSchulferienWeb.Admin, as: :admin do
    pipe_through :browser # Use the default browser stack

    # Locations
    #
    resources "/countries", CountryController
    resources "/federal_states", FederalStateController
    resources "/cities", CityController
    resources "/schools", SchoolController

    # Timetables
    #
    resources "/years", YearController
    resources "/months", MonthController
    resources "/days", DayController
    resources "/categories", CategoryController
    resources "/periods", PeriodController
    resources "/slots", SlotController
    resources "/inset_day_quantities", InsetDayQuantityController
  end

  # Other scopes may use custom stacks.
  # scope "/api", MehrSchulferienWeb do
  #   pipe_through :api
  # end
end
