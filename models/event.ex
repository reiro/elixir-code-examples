defmodule Stats.Event do
  require Logger
  use Stats.Web, :model
  use Timex
  alias Stats.Repo

  schema "events" do
    field :category, :string
    field :ad_id, :integer
    field :client_data, :map
    field :client_uid, :string

    timestamps
  end

  @required_fields ~w(category ad_id)
  @optional_fields ~w(client_uid client_data)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    Logger.debug "Event.changeset"
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:client_uid, name: :events_unique_index)
  end
end
