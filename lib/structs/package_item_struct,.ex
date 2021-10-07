defmodule PackageItem do
  @moduledoc "Responsible for defining Package Item structs"
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
