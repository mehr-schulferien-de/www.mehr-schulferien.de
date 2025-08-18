defmodule MehrSchulferienWeb.Plugs.Compression do
  @moduledoc """
  Plug to handle response compression for dynamic content.
  Supports gzip and deflate compression based on Accept-Encoding header.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if should_compress?(conn) do
      register_before_send(conn, &compress_response/1)
    else
      conn
    end
  end

  defp should_compress?(conn) do
    # Check if client accepts compression
    accept_encoding = get_req_header(conn, "accept-encoding") |> List.first() || ""

    # Only compress for HTML, JSON, and text responses
    content_type = get_resp_header(conn, "content-type") |> List.first() || ""

    compressible_type?(content_type) and
      (String.contains?(accept_encoding, "gzip") or String.contains?(accept_encoding, "deflate"))
  end

  defp compressible_type?(content_type) do
    Enum.any?([
      String.contains?(content_type, "text/html"),
      String.contains?(content_type, "application/json"),
      String.contains?(content_type, "text/css"),
      String.contains?(content_type, "application/javascript"),
      String.contains?(content_type, "text/javascript"),
      String.contains?(content_type, "text/plain"),
      String.contains?(content_type, "application/xml"),
      String.contains?(content_type, "text/xml")
    ])
  end

  defp compress_response(conn) do
    accept_encoding = get_req_header(conn, "accept-encoding") |> List.first() || ""
    body = conn.resp_body

    cond do
      # Skip if body is too small (< 1KB)
      is_binary(body) and byte_size(body) < 1024 ->
        conn

      # Skip if already compressed
      get_resp_header(conn, "content-encoding") != [] ->
        conn

      # Use gzip if supported
      String.contains?(accept_encoding, "gzip") ->
        compressed = :zlib.gzip(body)

        conn
        |> put_resp_header("content-encoding", "gzip")
        |> put_resp_header("vary", "Accept-Encoding")
        |> Map.put(:resp_body, compressed)

      # Use deflate as fallback
      String.contains?(accept_encoding, "deflate") ->
        z = :zlib.open()
        :zlib.deflateInit(z)
        compressed = :zlib.deflate(z, body, :finish)
        :zlib.close(z)

        conn
        |> put_resp_header("content-encoding", "deflate")
        |> put_resp_header("vary", "Accept-Encoding")
        |> Map.put(:resp_body, IO.iodata_to_binary(compressed))

      true ->
        conn
    end
  end
end
