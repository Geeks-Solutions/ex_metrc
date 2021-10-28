defmodule ExMetrc.MetrcAPI do
  @moduledoc """
  This module is responsible to abstract the calls to Metrc server
  """

  @doc """
  Routes to the GET request of the desired struct type.
  \nReturns:
   - `List` of the specified `Struct`
   - `{:error, reason}`

  ## Examples

      iex> ExMetrc.MetrcAPI.get("sales","Your_key","your_license_number",%{start_date: "2021-10-08}, end_date: "2021-10-12")
      [%Sale{...}, %Sale{...},...]

  """
  def get(struct, store_owner_key, store_license_number, filters \\ %{}) do
    if ApiProtocol.impl_for(struct) do
      ApiProtocol.get(struct, store_owner_key, store_license_number, filters)
    else
      {:error,
       "#{struct.__struct__ |> Module.split() |> Enum.join(".")} struct does not support this"}
    end
  end

  @doc """
  Routes to the GET active endpoint request of the desired struct type.
  \nReturns:
   - `List` of the specified `Struct`
   - `{:error, reason}`

  ## Examples

      iex> ExMetrc.MetrcAPI.get_active(%Package{},"Your_key","your_license_number",%{start_date: "2021-10-08, end_date: "2021-10-12"})
      [%Package{}{...}, %Package{}{...},...]

  """

  def get_active(struct, store_owner_key, store_license_number, filters \\ %{}) do
    if ApiProtocol.impl_for(struct) do
      ApiProtocol.get_active(struct, store_owner_key, store_license_number, filters)
    else
      {:error,
       "#{struct.__struct__ |> Module.split() |> Enum.join(".")} struct does not support this"}
    end
  end

  @doc """
  Routes to the GET by ID request of the desired struct type.
  \nReturns:
   - `Struct`.
   - `{:error, reason}`

  ## Examples

      iex> ExMetrc.MetrcAPI.get_by_id("products","Your_key","your_license_number", "12345")
      %Package{metrc_id: 12345,...}

  """
  def get_by_id(struct, store_owner_key, store_license_number, id, filters \\ %{}) do
    if ApiProtocol.impl_for(struct) do
      ApiProtocol.get_by_id(struct, store_owner_key, store_license_number, id, filters)
    else
      {:error,
       "#{struct.__struct__ |> Module.split() |> Enum.join(".")} struct does not support this"}
    end
  end

  @doc """
  Routes to the GET by label request of the desired struct type.
  \nReturns:
   - `Struct`.
   - `{:error, reason}`

  ## Examples

       iex> ExMetrc.MetrcAPI.get_by_label("products","Your_key","your_license_number", "label1234")
      %Package{label: "label1234",...}

  """
  def get_by_label(struct, store_owner_key, store_license_number, label, filters \\ %{}) do
    if ApiProtocol.impl_for(struct) do
      ApiProtocol.get_by_label(struct, store_owner_key, store_license_number, label, filters)
    else
      {:error,
       "#{struct.__struct__ |> Module.split() |> Enum.join(".")} struct does not support this"}
    end
  end
end
