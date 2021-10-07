defmodule ExMetrc.Helpers do
  @moduledoc """
  Helper functions for the library
  """
  def env(key, opts \\ %{default: nil, raise: false}) do
    Application.get_env(:ex_metrc, key)
    |> case do
      nil ->
        if opts |> Map.get(:raise, false),
          do: raise("Please configure :#{key} to use metrc API as desired,
          i.e:
          config, :ex_metrc,
            #{key}: VALUE_HERE "),
          else: opts |> Map.get(:default)

      value ->
        value
    end
  end

  def headers(store_owner_key) do
    [
      {"content-type", "application/json"},
      {"Authorization", authentication_header(store_owner_key)}
    ]
  end

  def authentication_header(store_owner_key) do
    "Basic " <> Base.encode64(vendor_api_key() <> ":" <> store_owner_key)
  end

  def vendor_api_key do
    env(:vendor_key, %{raise: true})
  end

  def endpoint do
    env(:endpoint, %{raise: false, default: "https://api-ca.metrc.com/"})
  end

  def metrc_url_endpoints(action) do
    case action do
      "get employees" ->
        endpoint() <> "employees/v1/"

      "get active packages" ->
        endpoint() <> "packages/v1/active/"

      "get sales" ->
        endpoint() <> "sales/v1/receipts/inactive/"

      _ ->
        {:error, :action_not_known}
    end
  end

  def endpoint_get_callback(
        url,
        headers \\ [{"content-type", "application/json"}]
      ) do
    case HTTPoison.get(url, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, error} ->
        {:error, error}
    end
  end

  def endpoint_put_callback(
        url,
        args,
        headers \\ [{"content-type", "application/json"}]
      ) do
    {:ok, body} = args |> Poison.encode()

    case HTTPoison.put(url, body, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, _error} ->
        {:error, "users credentials server error"}
    end
  end

  def endpoint_post_callback(
        url,
        args,
        headers \\ [{"content-type", "application/json"}]
      ) do
    {:ok, body} = args |> Poison.encode()

    case HTTPoison.post(url, body, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, _error} ->
        {:error, "users credentials server error"}
    end
  end

  def endpoint_delete_callback(
        url,
        headers \\ [{"content-type", "application/json"}]
      ) do
    # to use a delete request with a body
    # refer to Httpoison.request/5
    # {:ok, body} = args |> Poison.encode()

    case HTTPoison.delete(url, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, _error} ->
        {:error, "Metrc API server error"}
    end
  end

  defp fetch_response_body(response) do
    case Poison.decode(response.body) do
      {:ok, body} ->
        body

      _ ->
        {:error, response.body}
    end
  end

  def map_to_struct("employee", map) do
    license_map = Map.get(map, "License")

    employee_license =
      struct(EmployeeLicense, %{
        number: Map.get(license_map, "Number"),
        start_date: Map.get(license_map, "StartDate"),
        end_date: Map.get(license_map, "EndDate"),
        license_type: Map.get(license_map, "LicenseType")
      })

    struct(Employee, %{
      fullname: Map.get(map, "FullName"),
      license: employee_license
    })
  end

  def map_to_struct("package_item", map) do
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

  def map_to_struct("package", map) do
    package_item = map_to_struct("package_item", Map.get(map, "Item"))

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

  def validate_date(date, nullable \\ false) when is_binary(date) do
    if nullable && date == "" do
      :ok
    else
      case(Date.from_iso8601(date)) do
        {:ok, _} ->
          :ok

        {:error, _} ->
          case DateTime.from_iso8601(date) do
            {:ok, _, _} ->
              :ok

            error ->
              error
          end
      end
    end
  end

  def validate_date(_date, _nullable) do
    {:error, :invalid_params}
  end
end
