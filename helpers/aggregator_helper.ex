defmodule Stats.AggregatorHelper do
  require Logger
  import Ecto.Query, only: [from: 2, where: 3]
  alias Stats.Repo
  alias Stats.AppRepo
  alias Stats.Advertiser
  alias Stats.AdUnit
  alias Stats.Campaign

  use Timex

  def calculate_ad_events(ads, data, default) do
    q = Map.take(data, ads)
    Enum.reduce(q, default, fn({data_key, data_value}, accumulator) ->
         Enum.reduce(data_value, accumulator, fn({k, v}, acc) ->
             Map.update(acc, k, accumulator[k], fn(a) -> a + v end)
         end)
       end)
  end

  def calculate_ad_unit_events(ad_unit_id, data, default) do
    Enum.reduce(data, default, fn({data_key, data_value}, accumulator) ->
        if ad_unit_id == data_value.ad_unit_id do
            Enum.reduce(data_value.data, accumulator, fn({k, v}, acc) ->
                Map.update(acc, k, accumulator[k], fn(a) -> a + v end)
            end)
        else
            accumulator
        end
    end)
  end

  defp transform_date_default(date) do
    timezone = Timezone.get("Asia/Singapore", DateTime.now)
    date = Timezone.convert(date, timezone)
  end

  def transform_date_ad_unit(ad_unit, date) do
    if ad_unit != nil do
      ad_unit = ad_unit |> Repo.preload([:campaign])
      date = transform_date_campaign(ad_unit.campaign, date)
    else
      transform_date_default(date)
    end
  end

  def transform_date_campaign(campaign, date) do
    if campaign != nil && campaign.advertiser_id != nil do
      advertiser = Stats.AppRepo.get(Advertiser, campaign.advertiser_id)
      timezone = Timezone.get(advertiser.time_zone, DateTime.now)
      date = Timezone.convert(date, timezone)
    else
      transform_date_default(date)
    end
  end
end
