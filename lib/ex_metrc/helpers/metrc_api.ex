defmodule ExMetrc.MetrcAPI do
  @moduledoc """
  This module is responsible to abstract the calls to Metrc server
  """

  def get(struct, store_owner_key, store_license_number, filters \\ %{}) do
    if ApiProtocol.impl_for(struct) do
      ApiProtocol.get(struct, store_owner_key, store_license_number, filters)
    else
      {:error,
       "#{struct.__struct__ |> Module.split() |> Enum.join(".")} struct does not support this"}
    end
  end

  def get_by_id(struct, store_owner_key, store_license_number, id, filters \\ %{}) do
    if ApiProtocol.impl_for(struct) do
      ApiProtocol.get_by_id(struct, store_owner_key, store_license_number, id, filters)
    else
      {:error,
       "#{struct.__struct__ |> Module.split() |> Enum.join(".")} struct does not support this"}
    end
  end

  def get_by_label(struct, store_owner_key, store_license_number, label, filters \\ %{}) do
    if ApiProtocol.impl_for(struct) do
      ApiProtocol.get_by_label(struct, store_owner_key, store_license_number, label, filters)
    else
      {:error,
       "#{struct.__struct__ |> Module.split() |> Enum.join(".")} struct does not support this"}
    end
  end
end
