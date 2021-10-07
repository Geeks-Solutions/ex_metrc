defmodule ExMetrc.MetrcAPI do
  @moduledoc """
  This module is responsible to abstract the calls to Metrc server
  """
  alias ExMetrc.Helpers

  def get_employees(store_owner_key, store_license_number)
      when is_binary(store_owner_key) and is_binary(store_license_number) do
    url =
      Helpers.metrc_url_endpoints("get employees") <> "?licenseNumber=" <> store_license_number

    headers = Helpers.headers(store_owner_key)
    res = Helpers.endpoint_get_callback(url, headers)

    res =
      if is_list(res) do
        Enum.map(res, fn employee ->
          Helpers.map_to_struct("employee", employee)
        end)
      else
        case res do
          %{"Message" => message} ->
            {:error, message}

          {:error, ""} ->
            {:error, "Invalid License Number"}
        end
      end

    res
  end

  def get_employees(_store_owner_key, _store_license_number) do
    {:error, :invalid_params}
  end

  def get_products(store_owner_key, store_license_number, start_date, end_date \\ "")
      when is_binary(store_owner_key) and is_binary(store_license_number) do
    # validate start_date and end_date (end_date can be ommitted, in this case it will default to 24 hours)
    with :ok <- Helpers.validate_date(start_date),
         :ok <- Helpers.validate_date(end_date, true) do
      start_date = "&lastModifiedStart" <> start_date
      end_date = "&lastModifiedEnd=" <> end_date
      store_license_number = "?licenseNumber=" <> store_license_number

      url =
        Helpers.metrc_url_endpoints("get active packages") <>
          store_license_number <> start_date <> end_date

      headers = Helpers.headers(store_owner_key)

      res = Helpers.endpoint_get_callback(url, headers)

      res =
        if is_list(res) do
          Enum.map(res, fn package ->
            Helpers.map_to_struct("package", package)
          end)
        else
          case res do
            %{"Message" => message} ->
              {:error, message}

            {:error, ""} ->
              {:error, "Invalid License Number"}
          end
        end

      res
    else
      {:error, _} -> {:error, :invalid_date_formats}
    end
  end

  def get_products(_store_owner_key, _store_license_number, _start_date, _end_date) do
    {:error, :invalid_params}
  end
end
