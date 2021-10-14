defmodule Employee do
  @moduledoc "Responsible for defining Employee structs"
  defstruct fullname: "",
            license: %EmployeeLicense{}
end

defimpl StructProtocol, for: Employee do
  def map_to_struct(%Employee{}, map) do
    license_map = Map.get(map, "License")

    employee_license = StructProtocol.map_to_struct(%EmployeeLicense{}, license_map)

    struct(Employee, %{
      fullname: Map.get(map, "FullName"),
      license: employee_license
    })
  end
end

defimpl ApiProtocol, for: Employee do
  alias ExMetrc.Helpers

  @string_filters [:fullname]
  @min_integer_filters []
  @max_integer_filters []

  def get(%Employee{}, store_owner_key, store_license_number, opts \\ %{})
      when is_binary(store_owner_key) and is_binary(store_license_number) and is_map(opts) do
    opts =
      opts
      |> Map.new(fn {k, v} ->
        if is_atom(k) do
          {Atom.to_string(k) |> String.downcase() |> String.to_atom(), v}
        else
          {String.downcase(k) |> String.to_atom(), v}
        end
      end)

    url = Helpers.endpoint() <> "employees/v1/?licenseNumber=" <> store_license_number

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

        Helpers.filter(%Employee{}, res, %{
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
    nil
  end

  def get_by_label(_struct, _store_owner_key, _store_license_number, _label, _filters) do
    nil
  end
end
