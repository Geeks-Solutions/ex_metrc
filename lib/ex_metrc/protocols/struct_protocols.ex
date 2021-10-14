defprotocol ApiProtocol do
  def get(struct, store_owner_key, store_license_number, filters)

  def get_by_id(struct, store_owner_key, store_license_number, id, filters)

  def get_by_label(struct, store_owner_key, store_license_number, label, filters)
end

defprotocol StructProtocol do
  def map_to_struct(struct, map)
end
