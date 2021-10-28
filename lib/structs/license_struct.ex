defmodule License do
  @moduledoc """
  Responsible for defining License structs
  """
  @derive Jason.Encoder
  defstruct number: "",
            start_date: nil,
            end_date: nil,
            license_type: ""
end

defimpl StructProtocol, for: License do
  def map_to_struct(%License{}, map) do
    struct(License, %{
      number: Map.get(map, "Number"),
      start_date: Map.get(map, "StartDate"),
      end_date: Map.get(map, "EndDate"),
      license_type: Map.get(map, "LicenseType")
    })
  end
end
