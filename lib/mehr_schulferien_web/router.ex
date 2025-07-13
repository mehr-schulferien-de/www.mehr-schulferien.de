defmodule MehrSchulferienWeb.Router do
  use MehrSchulferienWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MehrSchulferienWeb.LocalePlug
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

  pipeline :pdf do
    plug :accepts, ["pdf"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # Add Swoosh mailbox preview in development
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # ========== Old Route Redirects (now redirecting /land/ to /ferien/) ==========
  scope "/", MehrSchulferienWeb do
    pipe_through :redirects

    # Redirect old /cities/ routes to SEO-friendly /ferien/ routes
    get "/cities/:city_slug/:year", RedirectController, :redirect_cities_with_year
    get "/cities/:city_slug", RedirectController, :redirect_cities

    # Redirect old /land/ routes to SEO-friendly /ferien/ routes
    get "/land/:country_slug/stadt/:city_slug/:year",
        RedirectController,
        :redirect_land_city_year_to_ferien

    get "/land/:country_slug/stadt/:city_slug", RedirectController, :redirect_land_city_to_ferien

    # Federal state redirects from /land/ to /ferien/
    get "/land/:country_slug/bundesland/:federal_state_slug/:year",
        RedirectController,
        :redirect_land_federal_state_year_to_ferien

    get "/land/:country_slug/bundesland/:federal_state_slug",
        RedirectController,
        :redirect_land_federal_state_to_ferien

    get "/land/:country_slug/bundesland/:federal_state_slug/landkreise-und-staedte",
        RedirectController,
        :redirect_land_counties_and_cities_to_ferien

    # School redirects from /land/ to /ferien/
    get "/land/:country_slug/schule/:school_slug/:year",
        RedirectController,
        :redirect_land_school_year_to_ferien

    get "/land/:country_slug/schule/:school_slug",
        RedirectController,
        :redirect_land_school_to_ferien

    # Bridge days redirects from /land/ to /ferien/
    get "/land/:country_slug/bundesland/:federal_state_slug/brueckentage",
        RedirectController,
        :redirect_land_bridge_days_to_ferien

    get "/land/:country_slug/bundesland/:federal_state_slug/brueckentage/:year",
        RedirectController,
        :redirect_land_bridge_days_year_to_ferien

    # Legacy routes that might still exist
    get "/feiertag/:country_slug/bundesland/:federal_state_slug/:holiday_or_vacation_type_slug",
        RedirectController,
        :redirect_public_holiday

    get "/landkreise-und-staedte/:country_slug/:federal_state_slug",
        RedirectController,
        :redirect_counties_and_cities
  end

  # ========== Main Routes (SEO-optimized /ferien/ URLs) ==========
  scope "/", MehrSchulferienWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/sommerferien", PageController, :summer_vacations
    get "/osterferien", PageController, :easter_vacations
    get "/herbstferien", PageController, :fall_vacations
    get "/weihnachtsferien", PageController, :christmas_vacations
    get "/winterferien", PageController, :winter_vacations
    get "/pfingstferien", PageController, :pentecost_vacations
    get "/developers", PageController, :developers
    get "/impressum", PageController, :impressum

    # Country routes (SEO-friendly pattern) - with non-year constraint
    get "/ferien/:country_slug", CountryController, :show,
      constraints: [country_slug: ~r/^(?!20[2-3][0-9]$)[a-zA-Z][a-zA-Z0-9_-]*$/]

    # Sitemap and robots
    get "/sitemap.xml", SitemapController, :sitemap
    get "/robots.txt", RobotsController, :index

    # Wiki section for collaborative school address editing
    live "/wiki/schools/new", WikiSchoolNewLive
    live "/wiki/schools/:slug", WikiSchoolShowLive
    post "/wiki/schools/:slug", WikiController, :update_school
    put "/wiki/schools/:slug", WikiController, :update_school
    delete "/wiki/schools/:slug", WikiController, :delete_school
    post "/wiki/schools/:slug/rollback/:version_id", WikiController, :rollback_school

    # Bewegliche Ferientage operations
    post "/wiki/schools/:slug/bewegliche-ferientage",
         WikiController,
         :create_beweglicher_ferientag

    delete "/wiki/schools/:slug/bewegliche-ferientage/:id",
           WikiController,
           :delete_beweglicher_ferientag

    # Federal state routes (SEO-friendly pattern)
    get "/ferien/:country_slug/bundesland/:federal_state_slug", FederalStateController, :show

    # Counties and cities - make sure this is before the year route
    get "/ferien/:country_slug/bundesland/:federal_state_slug/landkreise-und-staedte",
        FederalStateController,
        :county_show

    # Federal state with year - after more specific routes
    get "/ferien/:country_slug/bundesland/:federal_state_slug/:year",
        FederalStateController,
        :show_year,
        constraints: [year: ~r/20[2-3][0-9]/]

    # School search LiveView - MUST come before any catch-all routes
    live "/briefe/", SchoolSearchLive

    # School documents index page
    get "/briefe/:school_slug", SchoolController, :documents_index

    # Entschuldigung LiveView
    live "/briefe/:school_slug/entschuldigung", EntschuldigungLive

    # Beurlaubung LiveView
    live "/briefe/:school_slug/beurlaubung", BeurlaubungLive

    # Sportbefreiung LiveView
    live "/briefe/:school_slug/sportbefreiung", SportbefreiungLive

    # Next vacation URL
    get "/naechste-ferien/:federal_state_slug", VacationController, :next_vacation

    # Year-agnostic vacation URLs (redirect to current year)
    get "/:vacation_slug/:federal_state_slug", VacationController, :vacation_current,
      constraints: [vacation_slug: ~r/[a-z-]+ferien/]

    # Vacation routes - matches any vacation type from database
    get "/:vacation_slug/:federal_state_slug/:year", VacationController, :show,
      constraints: [year: ~r/20[2-3][0-9]/, vacation_slug: ~r/[a-z-]+ferien/]

    # City routes (SEO-friendly pattern)
    get "/ferien/:country_slug/stadt/:city_slug", CityController, :show

    get "/ferien/:country_slug/stadt/:city_slug/:year", CityController, :show_year,
      constraints: [year: ~r/20[2-3][0-9]/]

    # School routes (SEO-friendly pattern)
    get "/ferien/:country_slug/schule/:school_slug", SchoolController, :show

    # School vCard download - must come before the year route to avoid conflicts
    get "/ferien/:country_slug/schule/:school_slug/vcard", SchoolVCardController, :download,
      as: :school_vcard

    get "/ferien/:country_slug/schule/:school_slug/:year", SchoolController, :show_year,
      constraints: [year: ~r/20[2-3][0-9]/]

    # Legacy vCard path for backward compatibility
    get "/schule/:school_slug/vcard", SchoolVCardController, :download_legacy

    # Bridge days (SEO-friendly pattern)
    get "/brueckentage/:country_slug/bundesland/:federal_state_slug",
        BridgeDayController,
        :index_within_federal_state

    get "/brueckentage/:country_slug/bundesland/:federal_state_slug/:year",
        BridgeDayController,
        :show_within_federal_state,
        constraints: [year: ~r/20[2-3][0-9]/]
  end

  # PDF download routes
  scope "/", MehrSchulferienWeb do
    pipe_through :pdf

    # Document PDF downloads - consolidated
    get "/briefe/:school_slug/:document_type/pdf", DocumentPdfController, :download,
      constraints: [document_type: ~r/entschuldigung|beurlaubung|sportbefreiung/]
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
