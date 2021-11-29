defmodule PackageItem do
  @moduledoc """
  Responsible for defining Package Item structs
  """
  @derive Jason.Encoder
  defstruct name: "",
            quantity_type: nil,
            default_lab_testing_state: nil,
            unit_of_measurement_name: "",
            approval_status: nil,
            approval_status_date_time: "",
            strain_id: nil,
            administration_method: nil,
            unit_cbd_content_dose: nil,
            unit_cbd_content_dose_unit_of_measure_name: "",
            unit_thc_content_dose: nil,
            unit_thc_content_dose_unit_of_measure_name: "",
            number_of_doses: nil,
            public_ingredients: nil,
            description: "",
            is_used: nil
end

defimpl StructProtocol, for: PackageItem do
  def map_to_struct(%PackageItem{}, map) do
    struct(PackageItem, %{
      name: Map.get(map, "Name"),
      quantity_type: Map.get(map, "QuantityType"),
      default_lab_testing_state: Map.get(map, "DefaultLabTestingState"),
      unit_of_measurement_name: Map.get(map, "UnitOfMeasureName"),
      approval_status: Map.get(map, "ApprovalStatus"),
      approval_status_date_time: Map.get(map, "ApprovalStatusDateTime"),
      strain_id: Map.get(map, "StrainId"),
      administration_method: Map.get(map, "AdministrationMethod"),
      unit_cbd_content_dose: Map.get(map, "UnitCbdContentDose"),
      unit_cbd_content_dose_unit_of_measure_name:
        Map.get(map, "UnitCbdContentDoseUnitOfMeasureName"),
      unit_thc_content_dose: Map.get(map, "UnitThcContentDose"),
      unit_thc_content_dose_unit_of_measure_name:
        Map.get(map, "UnitThcContentDoseUnitOfMeasureName"),
      number_of_doses: Map.get(map, "NumberOfDoses"),
      public_ingredients: Map.get(map, "PublicIngredients"),
      description: Map.get(map, "Description"),
      is_used: Map.get(map, "IsUsed")
    })
  end
end
