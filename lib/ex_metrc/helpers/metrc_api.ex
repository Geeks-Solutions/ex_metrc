defmodule ExMetrc.MetrcAPI do
  @moduledoc """
  This module is responsible to abstract the calls to Metrc server
  """
  alias ExMetrc.Helpers

  def get_employees(store_owner_key, store_license_number) do
    ApiProtocol.get(%Employee{}, store_owner_key, store_license_number, %{})
  end

  def get_products(store_owner_key, store_license_number, filters \\ %{}) do
    ApiProtocol.get(%Package{}, store_owner_key, store_license_number, filters)
  end
end
