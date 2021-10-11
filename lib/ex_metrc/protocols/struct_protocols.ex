defprotocol ApiProtocol do
  @spec get(t, any, any, any) :: any
  def get(struct, store_owner_key, store_license_number, filters)
end

defprotocol StructProtocol do
  def map_to_struct(struct, map)
end
