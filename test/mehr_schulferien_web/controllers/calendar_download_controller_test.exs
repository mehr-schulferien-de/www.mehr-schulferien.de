defmodule MehrSchulferienWeb.CalendarDownloadControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.CalendarPdfFixtures

  alias MehrSchulferien.CalendarPdf.Store
  alias MehrSchulferien.Locations

  # The year gate never reads the real clock: every request pins "today".
  @today "today=01.03.2027"
  @state_path "/ferien/d/bundesland/hessen"
  @school_path "/ferien/d/schule/34117-goethe-gymnasium"

  setup do
    reset_calendar_pdfs()
    on_exit(&reset_calendar_pdfs/0)
    MehrSchulferien.Cache.clear_all_location_hierarchies()
    MehrSchulferien.Cache.clear_query_cache()

    {:ok, calendar_fixture()}
  end

  describe "download page of a federal state" do
    test "offers the four formats", %{conn: conn} do
      html = conn |> get("#{@state_path}/2027/download?#{@today}") |> html_response(200)

      assert html =~ "Schulferien Hessen 2027 als PDF"

      for file <- ~w(a3.pdf a4.pdf a5.pdf karte.pdf) do
        assert html =~ ~s(href="#{@state_path}/2027/download/#{file}")
      end
    end

    test "has its own title and canonical URL", %{conn: conn} do
      html = conn |> get("#{@state_path}/2027/download?#{@today}") |> html_response(200)

      assert html =~ ~r{<title>\s*Schulferien Hessen 2027 als PDF}
      assert html =~ ~r{rel="canonical" href="[^"]*#{@state_path}/2027/download"}
    end

    test "a past year redirects to the state page", %{conn: conn} do
      conn = get(conn, "#{@state_path}/2026/download?#{@today}")

      assert redirected_to(conn, 301) == @state_path
    end

    test "a year without vacation data is not found", %{conn: conn} do
      assert conn |> get("#{@state_path}/2028/download?#{@today}") |> html_response(404)
      assert conn |> get("#{@state_path}/abcd/download?#{@today}") |> html_response(404)
    end

    test "an unknown state is not found", %{conn: conn} do
      assert conn |> get("/ferien/d/bundesland/atlantis/2027/download") |> response(404)
    end
  end

  describe "PDF of a federal state" do
    test "is generated once and then served from the store", %{conn: conn} do
      Application.put_env(:mehr_schulferien, :calendar_pdf_stub_listener, self())

      conn = get(conn, "#{@state_path}/2027/download/a4.pdf?#{@today}")

      assert response(conn, 200) =~ "%PDF"
      assert get_resp_header(conn, "content-type") == ["application/pdf"]

      assert get_resp_header(conn, "content-disposition") ==
               [~s(inline; filename="schulferien-hessen-2027-a4.pdf")]

      assert_received {:calendar_pdf_compiled, _latex}

      again = get(build_conn(), "#{@state_path}/2027/download/a4.pdf?#{@today}")
      assert response(again, 200) =~ "%PDF"
      refute_received {:calendar_pdf_compiled, _latex}
    end

    test "unknown formats, files and years are not found", %{conn: conn} do
      for file <- ~w(a2.pdf a4 a4.png) do
        assert conn |> get("#{@state_path}/2027/download/#{file}?#{@today}") |> response(404)
      end

      assert conn |> get("#{@state_path}/2026/download/a4.pdf?#{@today}") |> response(404)
      assert conn |> get("#{@state_path}/2028/download/a4.pdf?#{@today}") |> response(404)
      assert Path.wildcard(Path.join(Store.dir(), "**/*.pdf")) == []
    end

    test "answers 503 with Retry-After when the PDF cannot be generated", %{conn: conn} do
      Application.put_env(:mehr_schulferien, :calendar_pdf_stub_result, :error)

      conn = get(conn, "#{@state_path}/2027/download/a4.pdf?#{@today}")

      assert response(conn, 503)
      assert get_resp_header(conn, "retry-after") == ["300"]
    end
  end

  describe "PDF of a school" do
    test "contains the school's own data", %{conn: conn} do
      conn = get(conn, "#{@school_path}/2027/download/karte.pdf?#{@today}")

      body = response(conn, 200)
      assert body =~ "Goethe-Gymnasium"
      assert body =~ "Ysenburgstraße 41"
      assert body =~ "Bewegl. Ferientag"

      assert get_resp_header(conn, "content-disposition") ==
               [~s(inline; filename="schulferien-34117-goethe-gymnasium-2027-karte.pdf")]
    end

    test "a quarantined school has no PDF", %{conn: conn, school: school} do
      {:ok, _school} = Locations.quarantine_school(school)

      assert conn |> get("#{@school_path}/2027/download/a4.pdf?#{@today}") |> response(404)
    end

    test "an unknown school is not found", %{conn: conn} do
      assert conn
             |> get("/ferien/d/schule/99999-gibt-es-nicht/2027/download/a4.pdf")
             |> response(404)
    end
  end

  describe "links to the downloads" do
    test "the state year page links to the download page", %{conn: conn} do
      html = conn |> get("#{@state_path}/2027?#{@today}") |> html_response(200)

      assert html =~ ~s(href="#{@state_path}/2027/download")
    end

    test "the evergreen state page links to the download page", %{conn: conn} do
      html = conn |> get("#{@state_path}?#{@today}") |> html_response(200)

      assert html =~ ~s(href="#{@state_path}/2027/download")
    end

    test "the city page links to the download page of its state", %{conn: conn} do
      html = conn |> get("/ferien/d/stadt/kassel?#{@today}") |> html_response(200)

      assert html =~ ~s(href="#{@state_path}/2027/download")
    end

    test "the school page links to its own PDFs", %{conn: conn} do
      html = conn |> get("#{@school_path}?#{@today}") |> html_response(200)

      for file <- ~w(a3.pdf a4.pdf a5.pdf karte.pdf) do
        assert html =~ ~s(href="#{@school_path}/2027/download/#{file}")
      end
    end

    test "the sitemap lists the download pages", %{conn: conn} do
      year = MehrSchulferien.Calendars.DateHelpers.today_berlin().year
      type = insert(:holiday_or_vacation_type, %{name: "Oster"})
      state = Locations.get_federal_state_by_slug("hessen")
      vacation(state, type, Date.new!(year, 3, 22), Date.new!(year, 4, 3))

      xml = conn |> get("/sitemap-bundeslaender.xml") |> response(200)

      assert xml =~ "https://www.mehr-schulferien.de#{@state_path}/#{year}/download</loc>"
    end

    test "robots.txt keeps crawlers away from the school PDFs", %{conn: conn} do
      assert conn |> get("/robots.txt") |> response(200) =~
               "Disallow: /ferien/*/schule/*/download/"
    end
  end
end
