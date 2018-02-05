defmodule Stats.AdUnit do
  require Logger
  use Stats.Web, :model

  schema "ad_units" do
    field :ads, {:array, :integer}
    field :original_id, :integer
    belongs_to :campaign, Stats.Campaign, references: :original_id

    timestamps
  end

  @required_fields ~w(ads original_id campaign_id)
  @optional_fields ~w()
  @event_types %{"clicks" => 0,
                 "impressions" => 0,
                 "swipes" => 0,
                 "5s_views" => 0,
                 "50%_views" => 0,
                 "100%_views" => 0,
                 "submits" => 0,
                 "likes" => 0,
                 "tw_shares" => 0,
                 "fb_shares" => 0,
                 "in_shares" => 0,
                 "wa_shares" => 0,
                 "email_shares" => 0}

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    Logger.debug "AdUnit.changeset"
    model
    |> cast(params, @required_fields, @optional_fields)
    |> foreign_key_constraint(:campaign_id)
  end

  def event_types do
    @event_types
  end
end
