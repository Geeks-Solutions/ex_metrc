defmodule ExMetrc.MetrcAPI do
  @moduledoc """
  This module is responsible to abstract the calls to Metrc server
  """

  @get_type_to_struct %{
    "employees" => %Employee{},
    "products" => %Package{},
    "sales" => %Sale{}
  }
  @get_by_id_type_to_struct %{
    "products" => %Package{},
    "sales" => %Sale{}
  }

  @get_by_label_type_to_struct %{
    "products" => %Package{}
  }
  def get(type, store_owner_key, store_license_number, filters \\ %{}) do
    case @get_type_to_struct[type] do
      nil -> {:error, :not_supported}
      struct -> ApiProtocol.get(struct, store_owner_key, store_license_number, filters)
    end
  end

  def get_by_id(type, store_owner_key, store_license_number, id, filters \\ %{}) do
    case @get_by_id_type_to_struct[type] do
      nil -> {:error, :not_supported}
      struct -> ApiProtocol.get_by_id(struct, store_owner_key, store_license_number, id, filters)
    end
  end

  def get_by_label(type, store_owner_key, store_license_number, label, filters \\ %{}) do
    case @get_by_label_type_to_struct[type] do
      nil ->
        {:error, :not_supported}

      struct ->
        ApiProtocol.get_by_label(struct, store_owner_key, store_license_number, label, filters)
    end
  end
end
