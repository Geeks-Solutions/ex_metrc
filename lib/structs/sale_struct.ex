defmodule Sale do
  @moduledoc "Responsible for defining Sale (receipts) structs"
  defstruct metrc_id: nil,
            receipt_number: "",
            sales_date_time: "",
            sales_customer_type: "",
            patient_license_number: "",
            caregiver_license_number: "",
            identification_method: "",
            total_packages: nil,
            total_price: nil,
            transactions: [%SaleTransaction{}],
            is_final: nil,
            archived_date: nil,
            recorded_date_time: "",
            recorded_by_username: "",
            last_modified: ""
end

defimpl ApiProtocol, for: Sale do
  alias ExMetrc.Helpers
  @string_filters [:recorded_by_username, :sales_customer_type]
  @min_integer_filters [:min_total_packages, :min_total_price]
  @max_integer_filters [:max_total_packages, :max_total_price]
  def get(%Sale{}, store_owner_key, store_license_number, opts \\ %{})
      when is_binary(store_owner_key) and is_binary(store_license_number) do
    opts =
      opts
      |> Map.new(fn {k, v} ->
        if is_atom(k) do
          {Atom.to_string(k) |> String.downcase() |> String.to_atom(), v}
        else
          {String.downcase(k) |> String.to_atom(), v}
        end
      end)

    start_date = Map.get(opts, :start_date, "")
    end_date = Map.get(opts, :end_date, "")

    with :ok <- Helpers.validate_date(start_date, true),
         :ok <- Helpers.validate_date(end_date, true) do
      headers = Helpers.headers(store_owner_key)
      store_license_number = "licenseNumber=" <> store_license_number
      dates_list = Helpers.split_dates(start_date, end_date)

      # For sales, there are 2 endpoints: active and inactive
      # active: receipt is not finalized by the store
      # inactive: receipt is finalized
      # A store can finalize a receipt whenever it wishes, can be days or weeks later, therefore
      # Always retrieve active and inactive sales for a specific date
      urls_list =
        Enum.map(dates_list, fn {start_date, end_date} ->
          start_date = if start_date != "", do: "&salesDateStart=" <> start_date, else: ""
          end_date = if end_date != "", do: "&salesDateEnd=" <> end_date, else: ""

          [
            Helpers.endpoint() <>
              "sales/v1/receipts/active/?" <>
              store_license_number <> start_date <> end_date,
            Helpers.endpoint() <>
              "sales/v1/receipts/inactive/?" <>
              store_license_number <> start_date <> end_date
          ]
        end)
        |> List.flatten()
        |> Enum.chunk_every(Helpers.requests_per_second())

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

      case List.first(res) do
        %{"Message" => message} ->
          {:error, message}

        {:error, ""} ->
          {:error, "Invalid License Number"}

        _ ->
          res =
            Enum.map(res, fn receipt ->
              # we need to send another API request to retrieve the items sold using the receipt ID
              receipt_id = Integer.to_string(Map.get(receipt, "Id"))

              url =
                Helpers.endpoint() <>
                  "sales/v1/receipts/" <>
                  receipt_id <> "?" <> store_license_number

              receipt_res = Helpers.endpoint_get_callback(url, headers)

              # receipt_transactions is a list of sale transaction containing information about the item sold
              # as well as total price and total quantity
              Map.put(receipt, "Transactions", Map.get(receipt_res, "Transactions"))
            end)

          {string_filters, min_integer_filters, max_integer_filters} =
            Helpers.split_filters(
              Map.delete(opts, :start_date)
              |> Map.delete(:end_date),
              @string_filters,
              @min_integer_filters,
              @max_integer_filters
            )

          Helpers.filter(%Sale{}, res, %{
            string: string_filters,
            min: min_integer_filters,
            max: max_integer_filters
          })
      end
    else
      {:error, _} -> {:error, :invalid_date_formats}
    end
  end

  def get_by_id(%Sale{}, store_owner_key, store_license_number, id, _filters) do
    headers = Helpers.headers(store_owner_key)
    store_license_number = "?licenseNumber=" <> store_license_number

    url = Helpers.endpoint() <> "sales/v1/receipts/" <> id <> store_license_number

    res = Helpers.endpoint_get_callback(url, headers)

    res =
      if is_map(res) do
        StructProtocol.map_to_struct(%Sale{}, res)
      else
        {:error, "Unauthorized or not found"}
      end

    res
  end

  def get_by_label(_struct, _store_owner_key, _store_license_number, _label, _filters) do
    {:error, :not_supported}
  end
end

defimpl StructProtocol, for: Sale do
  def map_to_struct(%Sale{}, map) do
    transactions =
      Map.get(map, "Transactions")
      |> Enum.map(fn transaction ->
        StructProtocol.map_to_struct(%SaleTransaction{}, transaction)
      end)

    struct(Sale, %{
      metrc_id: Map.get(map, "Id"),
      receipt_number: Map.get(map, "ReceiptNumber"),
      sales_date_time: Map.get(map, "SalesDateTime"),
      sales_customer_type: Map.get(map, "SalesCustomerType"),
      patient_license_number: Map.get(map, "PatientLicenseNumber"),
      caregiver_license_number: Map.get(map, "CaregiverLicenseNumber"),
      identification_method: Map.get(map, "IdentificationMethod"),
      total_packages: Map.get(map, "TotalPackages"),
      total_price: Map.get(map, "TotalPrice"),
      transactions: transactions,
      is_final: Map.get(map, "IsFinal"),
      archived_date: Map.get(map, "ArchivedDate"),
      recorded_date_time: Map.get(map, "RecordedDateTime"),
      recorded_by_username: Map.get(map, "RecordedByUserName"),
      last_modified: Map.get(map, "LastModified")
    })
  end
end
