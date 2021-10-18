defmodule Facility do
  defstruct hire_date: "",
            is_owner: nil,
            is_manager: nil,
            occupations: [],
            name: "",
            alias: "",
            display_name: "",
            credential_date: "",
            support_activation_date: "",
            support_expiration_date: "",
            support_last_paid_date: "",
            facility_type: %FacilityType{},
            license: %License{}
end

defimpl StructProtocol, for: Facility do
  def map_to_struct(%Facility{}, map) do
    license_map = Map.get(map, "License")
    facility_license = StructProtocol.map_to_struct(%License{}, license_map)

    facility_type_map = Map.get(map, "FacilityType")
    facility_type = StructProtocol.map_to_struct(%FacilityType{}, facility_type_map)

    struct(Facility, %{
      hire_date: Map.get(map, "HireDate"),
      is_owner: Map.get(map, "IsOwner"),
      is_manager: Map.get(map, "IsManager"),
      occupations: Map.get(map, "Occupations"),
      name: Map.get(map, "Name"),
      alias: Map.get(map, "Alias"),
      display_name: Map.get(map, "DisplayName"),
      credential_date: Map.get(map, "CredentialedDate"),
      support_activation_date: Map.get(map, "SupportActivationDate"),
      support_expiration_date: Map.get(map, "SupportExpirationDate"),
      support_last_paid_date: Map.get(map, "SupportLastPaidDate"),
      facility_type: facility_type,
      license: facility_license
    })
  end
end

defimpl ApiProtocol, for: Facility do
  alias ExMetrc.Helpers

  @string_filters [:name, :alias, :display_name]
  @min_integer_filters []
  @max_integer_filters []

  def get(%Facility{}, store_owner_key, _store_license_number, opts \\ %{})
      when is_binary(store_owner_key) and is_map(opts) do
    opts =
      opts
      |> Map.new(fn {k, v} ->
        if is_atom(k) do
          {Atom.to_string(k) |> String.downcase() |> String.to_atom(), v}
        else
          {String.downcase(k) |> String.to_atom(), v}
        end
      end)

    url = Helpers.endpoint() <> "facilities/v1"

    headers = Helpers.headers(store_owner_key)
    res = Helpers.endpoint_get_callback(url, headers)

    res =
      if is_list(res) do
        {string_filters, min_integer_filters, max_integer_filters} =
          Helpers.split_filters(
            opts,
            @string_filters,
            @min_integer_filters,
            @max_integer_filters
          )

        Helpers.filter(%Facility{}, res, %{
          string: string_filters,
          min: min_integer_filters,
          max: max_integer_filters
        })
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

  def get(_, _, _, _) do
    {:error, :invalid_params}
  end

  def get_by_id(_struct, _store_owner_key, _store_license_number, _id, _filters) do
    {:error, :not_supported}
  end

  def get_by_label(_struct, _store_owner_key, _store_license_number, _label, _filters) do
    {:error, :not_supported}
  end
end
