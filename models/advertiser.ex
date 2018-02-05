defmodule Stats.Advertiser do
  require Logger
  use Stats.Web, :model
  alias Stats.AppRepo

  schema "advertisers" do
    field :time_zone, :string
    has_many :campaigns, Stats.Campaign
  end
end
