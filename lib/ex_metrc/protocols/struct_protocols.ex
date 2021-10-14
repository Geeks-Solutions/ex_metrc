defprotocol ApiProtocol do
  @doc """
  Function to send a GET request to the specified struct
  """
  def get(struct, store_owner_key, store_license_number, filters)

  @doc """
  Function to send a GET by specified ID request to the specified struct
  """
  def get_by_id(struct, store_owner_key, store_license_number, id, filters)

  @doc """
  Function to send a GET by specified Label request to the specified struct
  """
  def get_by_label(struct, store_owner_key, store_license_number, label, filters)
end

defprotocol StructProtocol do
  @doc """
  Function to transform a given map to the given struct
  """
  def map_to_struct(struct, map)
end
