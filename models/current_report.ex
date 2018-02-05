defmodule Stats.CurrentReport do
  require Logger
  use Stats.Web, :model

  import Ecto.Query
  alias Stats.Repo

  schema "current_reports" do
    field :ad_id, :integer
    field :data, :map

    timestamps
  end

  @required_fields ~w(data)
  @optional_fields ~w(ad_id inserted_at)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    Logger.debug "CurrentReport.changeset"
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
