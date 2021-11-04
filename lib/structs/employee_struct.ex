defmodule Employee do
  @moduledoc """
  Responsible for defining Employee structs
  """
  @derive Jason.Encoder
  defstruct fullname: "",
            license: %License{}
end

defimpl StructProtocol, for: Employee do
  def map_to_struct(%Employee{}, map) do
    license_map = Map.get(map, "License")

    employee_license = StructProtocol.map_to_struct(%License{}, license_map)

    struct(Employee, %{
      fullname: Map.get(map, "FullName"),
      license: employee_license
    })
  end
end

defimpl ApiProtocol, for: Employee do
  alias ExMetrc.Helpers

  @string_filters [:fullname]
  @min_integer_filters []
  @max_integer_filters []

  def get(%Employee{}, store_owner_key, store_license_number, opts \\ %{})
      when is_binary(store_owner_key) and is_binary(store_license_number) and is_map(opts) do
    # 4 priorities:
    # 0 is synchronous
    # 1 is high asynchronous
    # 2 is medium asynchronous
    # 3 is low asynchronous

    opts =
      opts
      |> Map.new(fn {k, v} ->
        if is_atom(k) do
          {Atom.to_string(k) |> String.downcase() |> String.to_atom(), v}
        else
          {String.downcase(k) |> String.to_atom(), v}
        end
      end)

    priority = opts |> Map.get(:priority, 0)
    url = Helpers.endpoint() <> "employees/v1/?licenseNumber=" <> store_license_number

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
      "struct" => "employee",
      "opts" => opts
    }

    parent = self()
    Helpers.single_get_call(parent, args, meta, priority)
  end

  def get(_, _, _, _) do
    {:error, :invalid_params}
  end

  def get_by_id(_struct, _store_owner_key, _store_license_number, _id, _filters) do
    {:error, :not_supported}
  end

  def get_by_label(_struct, _store_owner_key, _store_license_number, _label, _filters) do
    {:error, :not_supported}
  end

  def get_active(_, _, _, _) do
    {:error, :not_supported}
  end
end
