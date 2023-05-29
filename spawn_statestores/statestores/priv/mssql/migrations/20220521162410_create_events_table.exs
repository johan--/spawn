defmodule Statestores.Adapters.MSSQLSnapshotAdapter.Migrations.CreateEventsTable do
  use Ecto.Migration

  def up do
    create table(:lookups, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :node, :string, primary_key: true
      add :actor, :string
      add :system, :string
      add :data, :binary
      timestamps([type: :utc_datetime_usec])
    end

    create unique_index(:lookups, [:id, :node])

    create table(:snapshots, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :actor, :string
      add :system, :string
      add :revision, :integer
      add :tags, :map
      add :data_type, :string
      add :data, :binary
      timestamps([type: :utc_datetime_usec])
    end
  end

  def down do
    drop table(:snapshots)
    drop table(:lookups)
  end
end
