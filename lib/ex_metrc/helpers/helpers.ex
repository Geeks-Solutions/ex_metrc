defmodule ExMetrc.Helpers do
  @moduledoc """
  Helper functions for the library
  """

  @one_day_in_seconds 86_400

  @doc """
  Retrieves the environment variable with the specified key
  """
  def env(key, opts \\ %{default: nil, raise: false}) do
    Application.get_env(:ex_metrc, key)
    |> case do
      nil ->
        if opts |> Map.get(:raise, false),
          do: raise("Please configure :#{key} to use metrc API as desired,
          i.e:
          config, :ex_metrc,
            #{key}: VALUE_HERE "),
          else: opts |> Map.get(:default)

      value ->
        value
    end
  end

  @doc """
  Creates the HTTP Request headers
  """

  def headers(store_owner_key) do
    [
      {"content-type", "application/json"},
      {"Authorization", authentication_header(store_owner_key)}
    ]
  end

  @doc """
  Creates the HTTP Request header specific for the Metrc API authentication
  \nReturns `Basic encoded_in_base_64`
  """
  def authentication_header(store_owner_key) do
    "Basic " <> Base.encode64(vendor_api_key() <> ":" <> store_owner_key)
  end

  @doc """
  Retrieves the vendor_api_key env variable
  """
  def vendor_api_key do
    env(:vendor_key, %{raise: true})
  end

  @doc """
  Retrieves the Metrc API base url env variable
  """
  def endpoint do
    env(:endpoint, %{raise: false, default: "https://api-ca.metrc.com/"})
  end

  @doc """
  Retrieves the desired number of requests per second used to send requests to Metrc API
  """
  def requests_per_second do
    env(:requests_per_second, %{raise: false, default: 3})
  end

  @doc """
  Function that handles sending the GET request to the url parameter with the headers and the response
  """
  def endpoint_get_callback(
        url,
        headers \\ [{"content-type", "application/json"}]
      ) do
    case HTTPoison.get(url, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Function that handles sending the PUT request to the url parameter with argument body and the headers and the response
  """
  def endpoint_put_callback(
        url,
        args,
        headers \\ [{"content-type", "application/json"}]
      ) do
    {:ok, body} = args |> Poison.encode()

    case HTTPoison.put(url, body, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, _error} ->
        {:error, "users credentials server error"}
    end
  end

  @doc """
  Function that handles sending the POST request to the url parameter with argument body and the headers and the response
  """
  def endpoint_post_callback(
        url,
        args,
        headers \\ [{"content-type", "application/json"}]
      ) do
    {:ok, body} = args |> Poison.encode()

    case HTTPoison.post(url, body, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, _error} ->
        {:error, "users credentials server error"}
    end
  end

  @doc """
  Function that handles sending the DELETE request to the url parameter with the headers and the response
  """
  def endpoint_delete_callback(
        url,
        headers \\ [{"content-type", "application/json"}]
      ) do
    # to use a delete request with a body
    # refer to Httpoison.request/5
    # {:ok, body} = args |> Poison.encode()

    case HTTPoison.delete(url, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, _error} ->
        {:error, "Metrc API server error"}
    end
  end

  defp fetch_response_body(response) do
    case Poison.decode(response.body) do
      {:ok, body} ->
        body

      _ ->
        {:error, response.body}
    end
  end

  @doc """
  Function that split a set of filters to the given filter lists:
  - String filters, where a value is checked if it equals the specific string filter
  - Minimum Integer filters, where a value is checked if it is less than the specific integer filter
  - Maximum Integer filters,  where a value is checked if it is more than the specific integer filter
  \nReturns:
  - {`map` of string_filters, `map` of integer filters,`map` of integer filters}

  ## Examples

      iex> ExMetrc.Helpers.split_filters(
        %{name: "ex_metrc",
          min_quantity: 7,
          measuring_unit: "Each",
          max_quantity: 12,
          min_not_exist: 7},[:name, :measuring_unit],[:min_quantity], [:max_quantity])
      {%{name: "ex_metrc, measuring_quantity: "Each"}, %{min_quantity: 7}, %{max_quantity: 12}}

  """
  def split_filters(filters_map, string_filters, min_integer_filters, max_integer_filters) do
    # we have 3 types of filtering, either strings ==, or integers less, or integers more
    # so we need to retrieve the values then filter based on this
    # to then get the integer filters, we need to remove min and max from the filter map and get the key
    # so the first 4 characters are always removed ("min_" and "max_")

    # First we split the filters map input to the 3 types we have
    string_filters =
      filters_map
      |> Map.take(string_filters)

    min_integer_filters =
      filters_map
      |> Map.take(min_integer_filters)
      |> Map.new(fn {key, value} ->
        {key |> Atom.to_string() |> String.slice(4..-1) |> String.to_atom(), value}
      end)

    max_integer_filters =
      filters_map
      |> Map.take(max_integer_filters)
      |> Map.new(fn {key, value} ->
        {key |> Atom.to_string() |> String.slice(4..-1) |> String.to_atom(), value}
      end)

    {string_filters, min_integer_filters, max_integer_filters}
  end

  @doc """
  Function that filters a list of maps to 3 types of filters (string, min integers, max integers) and then transforms it to the given struct
  \nReturns:
  - `List` of [`struct` of the given struct type]

  ## Examples

      iex> ExMetrc.Helpers.filter(%Package{},
        [ %{..., package_type: "P1", quantity: 5,...},
          %{..., package_type: "P1", quantity: 8,...},
          %{..., package_type: "P2", quantity: 1,...}
        ], %{
          string: %{package_type: "P1"},
          min: %{quantity: 4},
          max: %{quantity: 7}
        })
      [%Package{..., package_type: "P1", quantity: 5,...}]

  """
  def filter(struct, list, %{string: string_filters, min: min_filters, max: max_filters}) do
    # We need to iterate over the list retrieved from Metrc
    # Since the maps returned have different naming convention than snake case, transform it to the struct
    # then to a map to use Enum protocol
    # To filter the strings not equal to string filters while ignoring cases
    # then integers less than min integer filters
    # then integers more than max integer filters
    # then transform it back to structs
    Stream.map(list, fn object ->
      StructProtocol.map_to_struct(struct, object) |> Map.from_struct()
    end)
    |> Stream.reject(fn object ->
      object
      |> Enum.any?(fn {key, value} ->
        (key in Map.keys(string_filters) &&
           String.downcase(value) != String.downcase(Map.get(string_filters, key))) ||
          (key in Map.keys(min_filters) &&
             value < Map.get(min_filters, key)) ||
          (key in Map.keys(max_filters) &&
             value > Map.get(max_filters, key))
      end)
    end)
    |> Stream.map(fn object -> struct(struct, object) end)
    |> Enum.to_list()
  end

  @doc """
  Function that checks if a given string is parsable to date or datetime of ISO-8601 format or null if nullable is true
  \nReturns:
    - `:ok`
    - `{:error, reason}`

  ## Examples

      iex> ExMetrc.Helpers.validate_date("2021-10-08T04:23:59Z")
      :ok
  """
  def validate_date(date, nullable \\ false) when is_binary(date) do
    if nullable && date == "" do
      :ok
    else
      case(Date.from_iso8601(date)) do
        {:ok, _} ->
          :ok

        {:error, _} ->
          case DateTime.from_iso8601(date) do
            {:ok, _, _} ->
              :ok

            error ->
              error
          end
      end
    end
  end

  def validate_date(_date, _nullable) do
    {:error, :invalid_params}
  end

  @doc """
  Function that transforms strings in ISO8601 format (date or datetime) to datetime and returns a list of consecutive day tuples with at most 24 hours difference between 2 days in each tuple
  \nReturns:
    - `List` of `Tuple`

  ## Examples

      iex> ExMetrc.Helpers.split_dates("2021-10-07", "2021-10-08T04:23:59Z")
      [{"2021-10-07T00:00:00Z", "2021-10-08T00:00:00Z"}, {"2021-10-08T00:00:00Z", "2021-10-08T04:23:59Z"}]
  """
  def split_dates(start_date, end_date) do
    case {start_date, end_date} do
      {"", _} ->
        [{"", ""}]

      {start_date, ""} ->
        [{start_date, ""}]

      # the goal of this function is to return a list of tuple dates with at most 24 hours interval between them
      # first transform start_date and end_date to datetime with 00:00:00 time or if valid date_time to date_time (UTC)
      {start_date, end_date} ->
        start_date =
          case(Date.from_iso8601(start_date)) do
            {:ok, date} ->
              {:ok, datetime} = DateTime.new(date, Time.from_seconds_after_midnight(0))
              datetime

            {:error, _} ->
              {:ok, datetime, _} = DateTime.from_iso8601(start_date)
              datetime
          end

        end_date =
          case(Date.from_iso8601(end_date)) do
            {:ok, date} ->
              {:ok, datetime} = DateTime.new(date, Time.from_seconds_after_midnight(0))
              datetime

            {:error, _} ->
              {:ok, datetime, _} = DateTime.from_iso8601(end_date)
              datetime
          end

        # return this list
        dates_list_recursion(start_date, end_date)
    end
  end

  defp dates_list_recursion(start_date, end_date) do
    interval = DateTime.diff(end_date, start_date)

    if interval <= @one_day_in_seconds do
      [{DateTime.to_iso8601(start_date), DateTime.to_iso8601(end_date)}]
    else
      # 24 hours increment
      next_day = DateTime.add(start_date, @one_day_in_seconds)

      [{DateTime.to_iso8601(start_date), DateTime.to_iso8601(next_day)}] ++
        dates_list_recursion(next_day, end_date)
    end
  end
end
