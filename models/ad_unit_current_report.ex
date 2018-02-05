defmodule Stats.AdUnitCurrentReport do
  require Logger
  use Stats.Web, :model

  import Ecto.Query
  alias Stats.Repo

  schema "ad_unit_current_reports" do
    field :ad_unit_id, :integer
    field :content_type, :integer
    field :size, :integer
    field :data, :map

    timestamps
  end

  @required_fields ~w(data)
  @optional_fields ~w(ad_unit_id inserted_at content_type size)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    Logger.debug "AdUnitCurrentReport.changeset"
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def event_category(type) do
    %{"0" => "impressions",
      "1" => "clicks",
      "2" => "swipes",
      "3" => "5s_views",
      "4" => "50%_views",
      "5" => "100%_views",
      "6" => "submits",
      "7" => "likes",
      "8" => "tw_shares",
      "9" => "fb_shares",
      "10" => "in_shares",
      "11" => "wa_shares",
      "12" => "email_shares"
      }[type]
  end
end
