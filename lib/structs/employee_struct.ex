defmodule Employee do
  @moduledoc "Responsible for defining Employee structs"
  defstruct fullname: "",
            license: %EmployeeLicense{}
end
