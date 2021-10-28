defmodule ExMetrc.GetWorker do
  use Oban.Worker, queue: :ex_metrc_get
  import Ecto.Query, warn: false
  alias ExMetrc.Helpers
  @impl Worker

  @default_requests_per_second 150
  @string_to_struct %{
    "employee" => %Employee{},
    "package" => %Package{},
    "sale" => %Sale{},
    "facility" => %Facility{}
  }
  def perform(
        %{
          args: %{
            "headers" => headers,
            "url" => url,
            "priority" => priority,
            "filters" => filters,
            "struct" => struct,
            "opts" => opts
          },
          meta: _meta
        } = payload
      ) do
    case Hammer.check_rate(
           "GET_PER_SECOND_LIMIT" <> Integer.to_string(DateTime.utc_now() |> DateTime.to_unix()),
           1_000,
           Application.get_env(:ex_metrc, :requests_per_second, @default_requests_per_second)
         ) do
      {:allow, _count} ->
        payload_id = payload.id
        headers = headers |> Enum.map(fn map -> Map.to_list(map) end) |> List.flatten()
        struct = Map.get(@string_to_struct, struct)

        if priority == 0 do
          result = Helpers.endpoint_get_callback(url, headers)

          case result do
            res when is_list(res) ->
              {string_filters, min_integer_filters, max_integer_filters} =
                Helpers.split_filters(
                  opts,
                  Map.get(filters, "string_filters", []),
                  Map.get(filters, "min_integer_filters", []),
                  Map.get(filters, "max_integer_filters", [])
                )

              res =
                Helpers.filter(struct, res, %{
                  string: Helpers.atomize_keys(string_filters),
                  min: Helpers.atomize_keys(min_integer_filters),
                  max: Helpers.atomize_keys(max_integer_filters)
                })

              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "success", "result" => res})
                ]
              )

              send(:erlang.list_to_pid(Map.get(payload.args, "pid")), {:ok, res})
              :ok

            %{"Message" => _message} ->
              send(:erlang.list_to_pid(Map.get(payload.args, "pid")), {:error, :unauthorized})

              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "failure", "error" => :unauthorized})
                ]
              )

              :discard

            {:error, ""} ->
              error = :invalid_license_number
              send(:erlang.list_to_pid(Map.get(payload.args, "pid")), {:error, error})

              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "failure", "error" => error})
                ]
              )

              :discard

            {:error, %HTTPoison.Error{reason: :nxdomain}} ->
              send(:erlang.list_to_pid(Map.get(payload.args, "pid")), {:error, :nxdomain})

              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "failure", "error" => :nxdomain})
                ]
              )

              :discard

            {:error, %HTTPoison.Error{reason: :timeout}} ->
              # retry in 1 second
              {:snooze, 1}

            {:error, :not_found} ->
              error = :not_found
              send(:erlang.list_to_pid(Map.get(payload.args, "pid")), {:error, error})

              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "failure", "error" => error})
                ]
              )

              :discard

            res ->
              send(:erlang.list_to_pid(Map.get(payload.args, "pid")), {:ok, [res]})

              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "success", "result" => [res]})
                ]
              )

              :ok
          end
        else
          Helpers.endpoint_get_callback(url, headers)
          |> case do
            res when is_list(res) ->
              {string_filters, min_integer_filters, max_integer_filters} =
                Helpers.split_filters(
                  opts,
                  Map.get(filters, "string_filters", []),
                  Map.get(filters, "min_integer_filters", []),
                  Map.get(filters, "max_integer_filters", [])
                )

              res =
                Helpers.filter(struct, res, %{
                  string: Helpers.atomize_keys(string_filters),
                  min: Helpers.atomize_keys(min_integer_filters),
                  max: Helpers.atomize_keys(max_integer_filters)
                })

              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "success", "result" => res})
                ]
              )

              :ok

            %{"Message" => _message} ->
              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "failure", "error" => :unauthorized})
                ]
              )

              :discard

            {:error, ""} ->
              error = :invalid_license_number

              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "failure", "error" => error})
                ]
              )

              :discard

            {:error, %HTTPoison.Error{reason: :nxdomain}} ->
              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "failure", "error" => :nxdomain})
                ]
              )

              :discard

            {:error, %HTTPoison.Error{reason: :timeout}} ->
              # retry in 1 second
              {:snooze, 1}

            {:error, :not_found} ->
              error = :not_found

              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "failure", "error" => error})
                ]
              )

              :discard

            res ->
              from(p in "oban_jobs", where: p.id == ^payload_id)
              |> Helpers.repo().update_all(
                set: [
                  meta:
                    payload.meta
                    |> Map.merge(%{"status" => "success", "result" => [res]})
                ]
              )

              :ok
          end
        end

      {:deny, _limit} ->
        {:snooze, 1}
    end
  end
end
