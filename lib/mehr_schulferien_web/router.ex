defmodule MehrSchulferienWeb.Router do
  use MehrSchulferienWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MehrSchulferienWeb.Plugs.DateAssignsPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :redirects do
    plug :accepts, ["html"]
    plug :put_layout, false
    plug :put_status, 302
  end

  # ========== Old Route Redirects ==========
  scope "/", MehrSchulferienWeb do
    pipe_through :redirects

    # Old city routes
    get "/ferien/:country_slug/stadt/:city_slug/:year", RedirectController, :redirect_city_year
    get "/ferien/:country_slug/stadt/:city_slug", RedirectController, :redirect_city

    # Old federal state routes
    get "/ferien/:country_slug/bundesland/:federal_state_slug/:year",
        RedirectController,
        :redirect_federal_state_year

    get "/ferien/:country_slug/bundesland/:federal_state_slug",
        RedirectController,
        :redirect_federal_state

    get "/ferien/:country_slug/bundesland/:federal_state_slug/kategorie/:holiday_or_vacation_type_slug",
        RedirectController,
        :redirect_federal_state_category

    # Old school routes
    get "/ferien/:country_slug/schule/:school_slug/:year",
        RedirectController,
        :redirect_school_year

    get "/ferien/:country_slug/schule/:school_slug", RedirectController, :redirect_school

    # Old public holiday routes
    get "/feiertag/:country_slug/bundesland/:federal_state_slug/:holiday_or_vacation_type_slug",
        RedirectController,
        :redirect_public_holiday

    # Old bridge day routes
    get "/brueckentage/:country_slug/bundesland/:federal_state_slug",
        RedirectController,
        :redirect_bridge_days

    get "/brueckentage/:country_slug/bundesland/:federal_state_slug/:year",
        RedirectController,
        :redirect_bridge_days_year

    # Old misc routes
    get "/landkreise-und-staedte/:country_slug/:federal_state_slug",
        RedirectController,
        :redirect_counties_and_cities
  end

  # ========== New Routes ==========
  scope "/", MehrSchulferienWeb do
    pipe_through :browser

    get "/", PageController, :new
    get "/sommerferien", PageController, :summer_vacations
    get "/developers", PageController, :developers
    get "/impressum", PageController, :impressum

    # SEO Optimized URLs for yearly views
    get "/ferien/:year", PageController, :full_year,
      constraints: [year: [format: ~r/20[2-3][0-9]/]]

    # Shows current year
    get "/ferien", PageController, :full_year

    # Sitemap and robots
    get "/sitemap.xml", SitemapController, :index
    get "/robots.txt", RobotsController, :index

    # Country routes (consistent pattern)
    get "/land/:country_slug", CountryController, :show

    # Federal state routes (consistent pattern)
    get "/land/:country_slug/bundesland/:federal_state_slug", FederalStateController, :show

    # Counties and cities - make sure this is before the year route
    get "/land/:country_slug/bundesland/:federal_state_slug/landkreise-und-staedte",
        FederalStateController,
        :county_show

    # Federal state with year - after more specific routes
    get "/land/:country_slug/bundesland/:federal_state_slug/:year",
        FederalStateController,
        :show_year,
        constraints: [year: [format: ~r/20[2-3][0-9]/]]

    get "/land/:country_slug/bundesland/:federal_state_slug/kategorie/:holiday_or_vacation_type_slug",
        FederalStateController,
        :show_holiday_or_vacation_type

    # City routes (consistent pattern)
    get "/land/:country_slug/stadt/:city_slug", CityController, :show

    get "/land/:country_slug/stadt/:city_slug/:year", CityController, :show_year,
      constraints: [year: [format: ~r/20[2-3][0-9]/]]

    # School routes (consistent pattern)
    get "/land/:country_slug/schule/:school_slug", SchoolController, :show

    get "/land/:country_slug/schule/:school_slug/:year", SchoolController, :show_year,
      constraints: [year: [format: ~r/20[2-3][0-9]/]]

    # School vCard download - consistent with school routes
    get "/land/:country_slug/schule/:school_slug/vcard", SchoolVCardController, :download,
      as: :school_vcard

    # Legacy vCard path for backward compatibility
    get "/schule/:school_slug/vcard", SchoolVCardController, :download_legacy

    # Public holidays (consistent pattern)
    get "/land/:country_slug/bundesland/:federal_state_slug/feiertage/:holiday_or_vacation_type_slug",
        PublicHolidayController,
        :show_within_federal_state

    # Bridge days (consistent pattern)
    get "/land/:country_slug/bundesland/:federal_state_slug/brueckentage",
        BridgeDayController,
        :index_within_federal_state

    get "/land/:country_slug/bundesland/:federal_state_slug/brueckentage/:year",
        BridgeDayController,
        :show_within_federal_state,
        constraints: [year: [format: ~r/20[2-3][0-9]/]]
  end

  scope "/api/v2.0", MehrSchulferienWeb.Api.V2, as: :api do
    pipe_through :api

    resources "/locations", LocationController, only: [:index, :show]
    resources "/periods", PeriodController, only: [:index, :show]
    resources "/holiday_or_vacation_types", HolidayOrVacationTypeController, only: [:index, :show]
    get "/vcards/schools/:slug", VCardController, :school_show
    get "/icalendars/location/:slug", ICalController, :show
  end
end
