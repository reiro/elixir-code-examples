defmodule Stats.AdUnitEvent do
  require Logger
  use Stats.Web, :model
  use Timex
  alias Stats.Repo

  schema "ad_unit_events" do
    field :category, :integer
    field :ad_unit_id, :integer
    field :content_type, :integer
    field :size, :integer
    field :ad_id, :integer
    field :client_data, :map
    field :client_uid, :string

    timestamps
  end

  @required_fields ~w(category ad_unit_id content_type
   size client_uid client_data)
  @optional_fields ~w(ad_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    Logger.debug "AdUnitEvent.changeset"
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:client_uid, name: :ad_unit_events_unique_index)
  end
end
