defmodule Package do
  @moduledoc "Responsible for defining Package structs"
  defstruct metrc_id: "",
            label: "",
            package_type: "",
            source_harvest_names: nil,
            location_id: nil,
            location_name: nil,
            location_type_name: nil,
            quantity: nil,
            unit_of_measure_name: "",
            unit_of_measure_abbreviation: "",
            patient_license_number: nil,
            item_from_facility_license_number: nil,
            item_from_facility_name: nil,
            note: nil,
            package_date: "",
            initial_lab_testing_state: "",
            lab_testing_state: "",
            lab_testing_state_date: "",
            is_production_batch: nil,
            production_batch_number: nil,
            source_production_batch_numbers: nil,
            is_trade_sample: nil,
            is_trade_sample_persistent: nil,
            source_package_is_trade_sample: nil,
            is_donation: nil,
            is_donation_persistent: nil,
            source_package_is_donation: nil,
            is_testing_sample: nil,
            is_process_validation_testing_sample: nil,
            product_requires_remidiation: nil,
            contains_remediated_product: nil,
            remediation_date: nil,
            received_date_time: nil,
            received_from_manifest_number: nil,
            received_from_facility_license_number: nil,
            received_from_facility_name: nil,
            is_on_hold: nil,
            archived_date: nil,
            finished_date: nil,
            last_modified: "",
            item: %PackageItem{}
end

defimpl ApiProtocol, for: Package do
  alias ExMetrc.Helpers

  @string_filters [:package_type, :item_from_facility_license_number, :unit_of_measure_name]
  @min_integer_filters [:min_quantity]
  @max_integer_filters [:max_quantity]
  def get(%Package{}, store_owner_key, store_license_number, opts \\ %{})
      when is_binary(store_owner_key) and is_binary(store_license_number) and is_map(opts) do
    # to avoid any errors later on, transform filters map to downcased atom keys
    opts =
      opts
      |> Map.new(fn {k, v} ->
        if is_atom(k) do
          {Atom.to_string(k) |> String.downcase() |> String.to_atom(), v}
        else
          {String.downcase(k) |> String.to_atom(), v}
        end
      end)

    # validate start_date and end_date (end_date can be ommitted, in this case it will default to 24 hours)
    start_date = Map.get(opts, :start_date, "")
    end_date = Map.get(opts, :end_date, "")

    with :ok <- Helpers.validate_date(start_date, true),
         :ok <- Helpers.validate_date(end_date, true) do
      # we need to partition the given dates / datetimes to a list of 24 hours difference
      # for example if start_date: 2021-10-07 and end_date: 2021-10-09:
      #   - We need to send 2 requests:
      #     - one start_date 2021-10-07 and end_date 2021-10-08
      #     - one start_date 2021-10-08 and end_date 2021-10-09
      #   - We need to also limit the number of requests per second, for this:
      #     - Set the amount of requests per second in the config file
      #     - Send a batch of requests every 1 second

      headers = Helpers.headers(store_owner_key)
      store_license_number = "licenseNumber=" <> store_license_number

      dates_list = Helpers.split_dates(start_date, end_date)

      urls_list =
        Enum.map(dates_list, fn {start_date, end_date} ->
          start_date = if start_date != "", do: "&lastModifiedStart=" <> start_date, else: ""
          end_date = if end_date != "", do: "&lastModifiedEnd=" <> end_date, else: ""

          Helpers.endpoint() <>
            "packages/v1/active/?" <>
            store_license_number <> start_date <> end_date
        end)
        |> Enum.chunk_every(Helpers.requests_per_second())

      # urls_list now is a list of: list of query strings where the maximum length is the number of requests per second
      # we need to perform the requests in every batch together, then wait a second
      res =
        Enum.map(urls_list, fn urls ->
          Task.async(fn ->
            Enum.map(urls, fn url -> Helpers.endpoint_get_callback(url, headers) end)
          end)
        end)
        |> Enum.map(fn task ->
          :timer.sleep(1000)
          Task.await(task, 5000)
        end)
        |> List.flatten()

      # now we need to transform it to structs and filter them
      # or return 1 message from all the request where the license number or api key unauthorized
      # check the first response of all the responses only, since same credentials are used in all the requests

      case List.first(res) do
        %{"Message" => message} ->
          {:error, message}

        {:error, ""} ->
          {:error, "Invalid License Number"}

        _ ->
          {string_filters, min_integer_filters, max_integer_filters} =
            Helpers.split_filters(
              Map.delete(opts, :start_date)
              |> Map.delete(:end_date),
              @string_filters,
              @min_integer_filters,
              @max_integer_filters
            )

          Helpers.filter(%Package{}, res, %{
            string: string_filters,
            min: min_integer_filters,
            max: max_integer_filters
          })
      end
    else
      {:error, _} -> {:error, :invalid_date_formats}
    end
  end

  def get(_, _, _, _) do
    {:error, :invalid_params}
  end

  def get_by_id(%Package{}, store_owner_key, store_license_number, id, _filters) do
    headers = Helpers.headers(store_owner_key)
    store_license_number = "?licenseNumber=" <> store_license_number

    url = Helpers.endpoint() <> "packages/v1/" <> id <> store_license_number

    res = Helpers.endpoint_get_callback(url, headers)

    res =
      if is_map(res) do
        StructProtocol.map_to_struct(%Package{}, res)
      else
        {:error, "Unauthorized or not found"}
      end

    res
  end

  def get_by_label(%Package{}, store_owner_key, store_license_number, label, _filters) do
    headers = Helpers.headers(store_owner_key)
    store_license_number = "?licenseNumber=" <> store_license_number

    url = Helpers.endpoint() <> "packages/v1/" <> label <> store_license_number

    res = Helpers.endpoint_get_callback(url, headers)

    res =
      if is_map(res) do
        StructProtocol.map_to_struct(%Package{}, res)
      else
        {:error, "Unauthorized or not found"}
      end

    res
  end
end

defimpl StructProtocol, for: Package do
  def map_to_struct(%Package{}, map) do
    package_item = StructProtocol.map_to_struct(%PackageItem{}, Map.get(map, "Item"))

    struct(Package, %{
      metrc_id: Map.get(map, "Id"),
      label: Map.get(map, "Label"),
      package_type: Map.get(map, "PackageType"),
      package_date: Map.get(map, "PackagedDate"),
      quantity: Map.get(map, "Quantity"),
      unit_of_measure_name: Map.get(map, "UnitOfMeasureName"),
      unit_of_measure_abbreviation: Map.get(map, "UnitOfMeasureAbbreviation"),
      source_harvest_names: Map.get(map, "SourceHarvestNames"),
      source_production_batch_numbers: Map.get(map, "SourceProductionBatchNumbers"),
      is_production_batch: Map.get(map, "IsProductionBatch"),
      production_batch_number: Map.get(map, "ProductionBatchNumber"),
      is_trade_sample: Map.get(map, "IsTradeSample"),
      is_trade_sample_persistent: Map.get(map, "IsTradeSamplePersistent"),
      is_testing_sample: Map.get(map, "IsTestingSample"),
      is_process_validation_testing_sample: Map.get(map, "IsProcessValidationTestingSample"),
      is_donation_persistent: Map.get(map, "IsDonationPersistent"),
      is_on_hold: Map.get(map, "IsOnHold"),
      location_id: Map.get(map, "LocationId"),
      location_name: Map.get(map, "LocationName"),
      location_type_name: Map.get(map, "LocationTypeName"),
      patient_license_number: Map.get(map, "PatientLicenseNumber"),
      note: Map.get(map, "Note"),
      initial_lab_testing_state: Map.get(map, "InitialLabTestingState"),
      lab_testing_state: Map.get(map, "LabTestingState"),
      lab_testing_state_date: Map.get(map, "LabTestingStateDate"),
      source_package_is_trade_sample: Map.get(map, "SourcePackageIsTradeSample"),
      is_donation: Map.get(map, "IsDonation"),
      source_package_is_donation: Map.get(map, "SourcePackageIsDonation"),
      product_requires_remidiation: Map.get(map, "ProductRequiresRemediation"),
      contains_remediated_product: Map.get(map, "ContainsRemediatedProduct"),
      remediation_date: Map.get(map, "RemediationDate"),
      received_from_manifest_number: Map.get(map, "ReceivedFromManifestNumber"),
      received_from_facility_license_number: Map.get(map, "ReceivedFromFacilityLicenseNumber"),
      received_from_facility_name: Map.get(map, "ReceivedFromFacilityName"),
      received_date_time: Map.get(map, "ReceivedDateTime"),
      item_from_facility_license_number: Map.get(map, "ItemFromFacilityLicenseNumber"),
      item_from_facility_name: Map.get(map, "ItemFromFacilityName"),
      item: package_item,
      archived_date: Map.get(map, "ArchivedDate"),
      finished_date: Map.get(map, "FinishedDate"),
      last_modified: Map.get(map, "LastModified")
    })
  end
end
