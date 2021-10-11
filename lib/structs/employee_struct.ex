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

  # No filters available in get employees
  def get(%Employee{}, store_owner_key, store_license_number, _filters)
      when is_binary(store_owner_key) and is_binary(store_license_number) do
    url = Helpers.metrc_url_endpoints("get employees") <> "licenseNumber=" <> store_license_number

    headers = Helpers.headers(store_owner_key)
    res = Helpers.endpoint_get_callback(url, headers)

    res =
      if is_list(res) do
        Enum.map(res, fn employee ->
          StructProtocol.map_to_struct(%Employee{}, employee)
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
end
