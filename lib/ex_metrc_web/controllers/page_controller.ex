defmodule ExMetrcWeb.PageController do
  use ExMetrcWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
