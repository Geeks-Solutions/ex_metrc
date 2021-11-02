defmodule Sale do
  @moduledoc """
  Responsible for defining Sale (receipt) structs
  """
  @derive Jason.Encoder
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

      priority = opts |> Map.get(:priority, 2)

      headers =
        Helpers.headers(store_owner_key) |> Enum.map(fn {key, value} -> %{key => value} end)

      store_license_number = "licenseNumber=" <> store_license_number

      dates_list = Helpers.split_dates(start_date, end_date)

      # For sales, there are 2 endpoints: active and inactive
      # active: receipt is not finalized by the store
      # inactive: receipt is finalized
      # A store can finalize a receipt whenever it wishes, can be days or weeks later, therefore
      # Always retrieve active and inactive sales for a specific date
      urls_list =
        Enum.map(dates_list, fn {start_date, end_date} ->
          start_date = if start_date != "", do: "&lastModifiedStart=" <> start_date, else: ""

          end_date = if end_date != "", do: "&lastModifiedEnd=" <> end_date, else: ""

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

      args = %{
        "headers" => headers,
        "priority" => priority,
        "filters" => %{
          string_filters: @string_filters,
          min_integer_filters: @min_integer_filters,
          max_integer_filters: @max_integer_filters
        },
        "struct" => "sale",
        "opts" => opts,
        "store_license_number" => store_license_number
      }

      meta = %{status: "pending"}
      parent = self()
      Helpers.multiple_get_calls(parent, args, urls_list, meta, priority)
    else
      {:error, _} -> {:error, :invalid_date_formats}
    end
  end

  def get(_, _, _, _) do
    {:error, :invalid_params}
  end

  def get_by_id(%Sale{}, store_owner_key, store_license_number, id, opts \\ %{}) do
    opts =
      opts
      |> Map.new(fn {k, v} ->
        if is_atom(k) do
          {Atom.to_string(k) |> String.downcase() |> String.to_atom(), v}
        else
          {String.downcase(k) |> String.to_atom(), v}
        end
      end)

    priority = opts |> Map.get(:priority, 2)
    store_license_number = "?licenseNumber=" <> store_license_number
    url = Helpers.endpoint() <> "sales/v1/receipts/" <> id <> store_license_number

    headers = Helpers.headers(store_owner_key) |> Enum.map(fn {key, value} -> %{key => value} end)
    meta = %{status: "pending"}

    args = %{
      "url" => url,
      "headers" => headers,
      "priority" => priority,
      "filters" => %{
        string_filters: @string_filters,
        min_integer_filters: @min_integer_filters,
        max_integer_filters: @max_integer_filters
      },
      "struct" => "sale",
      "opts" => opts
    }

    parent = self()
    Helpers.single_get_call(parent, args, meta, priority)
  end

  def get_by_id(_, _, _, _, _) do
    {:error, :invalid_params}
  end

  def get_by_label(_struct, _store_owner_key, _store_license_number, _label, _filters) do
    {:error, :not_supported}
  end

  def get_active(_, _, _, _) do
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
