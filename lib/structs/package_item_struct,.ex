defmodule PackageItem do
  defstruct metrc_id: nil,
            name: "",
            product_category_name: "",
            product_category_type: nil,
            quantity_type: nil,
            default_lab_testing_state: nil,
            unit_of_measurement_name: "",
            approval_status: nil,
            approval_status_date_time: "",
            strain_id: nil,
            strain_name: "",
            administration_method: nil,
            unit_cbd_percent: nil,
            unit_cbd_content: nil,
            unit_cbd_content_unit_of_measure_name: "",
            unit_cbd_content_dose: nil,
            unit_cbd_content_dose_unit_of_measure_name: "",
            unit_thc_percent: nil,
            unit_thc_content: nil,
            unit_thc_content_unit_of_measure_name: "",
            unit_thc_content_dose: nil,
            unit_thc_content_dose_unit_of_measure_name: "",
            unit_volume: nil,
            unit_volume_unit_of_measure_name: "",
            unit_weight: nil,
            unit_weight_unit_of_measure_name: "",
            serving_size: nil,
            supply_duration_days: nil,
            number_of_doses: nil,
            unit_quantity: nil,
            unit_quantity_unit_of_measure_name: "",
            public_ingredients: nil,
            description: "",
            is_used: nil
end