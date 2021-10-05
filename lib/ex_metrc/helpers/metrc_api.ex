defmodule ExMetrc.MetrcAPI do
  @moduledoc """
  This module is responsible to abstract the calls to Metrc server
  """
  alias ExMetrc.Helpers

  def get_employees(store_owner_key, store_license_number)
      when is_binary(store_owner_key) and is_binary(store_license_number) do
    url = Helpers.endpoint() <> "employees/v1/?licenseNumber=" <> store_license_number
    headers = Helpers.headers(store_owner_key)
    res = Helpers.endpoint_get_callback(url, headers)

    res =
      if(is_list(res)) do
        Enum.map(res, fn employee ->
          struct(Employee, %{
            fullname: Map.get(employee, "FullName"),
            license: Map.get(employee, "License")
          })
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

  def get_products(store_owner_key, store_license_number)
      when is_binary(store_owner_key) and is_binary(store_license_number) do
    url = Helpers.endpoint() <> "packages/v1/inactive?licenseNumber=" <> store_license_number
    headers = Helpers.headers(store_owner_key)
    Helpers.endpoint_get_callback(url, headers)
  end

  def get_products(_store_owner_key, _store_license_number) do
    {:error, :invalid_params}
  end

  def get_facilities(store_owner_key) when is_binary(store_owner_key) do
    # get list of stores the store owner has
  end
end
