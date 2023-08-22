defmodule Statestores.Adapters.MSSQLSnapshotAdapter do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.SnapshotBehaviour` for MSSQL databases.
  """
  use Statestores.Adapters.SnapshotBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.Tds

  alias Statestores.Schemas.{Snapshot, ValueObjectSchema}

  def get_by_key(id), do: get_by(Snapshot, id: id)

  def get_by_key_and_revision(_id, _revision), do: raise("Not implemented")

  def get_all_snapshots_by_key(_id), do: raise("Not implemented")

  def get_snapshots_by_interval(_id, _time_start, _time_end), do: raise("Not implemented")

  def save(%Snapshot{id: id} = event) do
    %Snapshot{}
    |> Snapshot.changeset(ValueObjectSchema.to_map(event))
    |> insert()
    |> case do
      {:ok, event} ->
        {:ok, event}

      {:error, changeset} ->
        {:error, changeset}

      other ->
        {:error, other}
    end
  rescue
    _e ->
      get_by(Snapshot, id: id)
      |> Snapshot.changeset(ValueObjectSchema.to_map(event))
      |> update!()
      |> case do
        {:ok, event} ->
          {:ok, event}

        {:error, changeset} ->
          {:error, changeset}

        other ->
          {:error, other}
      end
  end

  def default_port, do: "1433"
end
