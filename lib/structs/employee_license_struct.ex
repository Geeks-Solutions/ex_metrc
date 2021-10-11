defmodule EmployeeLicense do
  @moduledoc "Responsible for defining Employee License structs"
  defstruct number: "",
            start_date: nil,
            end_date: nil,
            license_type: ""
end

defimpl StructProtocol, for: EmployeeLicense do
  def map_to_struct(%EmployeeLicense{}, map) do
    struct(EmployeeLicense, %{
      number: Map.get(map, "Number"),
      start_date: Map.get(map, "StartDate"),
      end_date: Map.get(map, "EndDate"),
      license_type: Map.get(map, "LicenseType")
    })
  end
end
