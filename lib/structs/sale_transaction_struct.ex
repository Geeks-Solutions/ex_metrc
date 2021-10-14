defmodule SaleTransaction do
  @moduledoc "Responsible for defining SaleTransaction (items sold in a sale) structs"
  defstruct package_id: nil,
            package_label: "",
            item_unit_cbd_content_dose: nil,
            item_unit_cbd_content_dose_unit_of_measure_name: nil,
            item_unit_thc_content_dose: nil,
            item_unit_thc_content_dose_unit_of_measure_name: nil,
            quantity_sold: nil,
            unit_of_measure_name: "",
            unit_of_measure_abbreviation: "",
            total_price: nil,
            sales_delivery_state: nil,
            archived_date: nil,
            recorded_date_time: "",
            recorded_by_username: nil,
            last_modified: ""
end

defimpl StructProtocol, for: SaleTransaction do
  def map_to_struct(%SaleTransaction{}, map) do
    struct(SaleTransaction, %{
      package_id: Map.get(map, "PackageId"),
      package_label: Map.get(map, "PackageLabel"),
      item_unit_cbd_content_dose: Map.get(map, "ItemUnitCbdContentDose"),
      item_unit_cbd_content_dose_unit_of_measure_name:
        Map.get(map, "ItemUnitCbdContentDoseUnitOfMeasureName"),
      item_unit_thc_content_dose: Map.get(map, "ItemUnitThcContentDose"),
      item_unit_thc_content_dose_unit_of_measure_name:
        Map.get(map, "ItemUnitThcContentDoseUnitOfMeasureName"),
      quantity_sold: Map.get(map, "QuantitySold"),
      unit_of_measure_name: Map.get(map, "UnitOfMeasureName"),
      unit_of_measure_abbreviation: Map.get(map, "UnitOfMeasureAbbreviation"),
      total_price: Map.get(map, "TotalPrice"),
      sales_delivery_state: Map.get(map, "SalesDeliveryState"),
      archived_date: Map.get(map, "ArchivedDate"),
      recorded_date_time: Map.get(map, "RecordedDateTime"),
      recorded_by_username: Map.get(map, "RecordedByUserName"),
      last_modified: Map.get(map, "LastModified")
    })
  end
end
