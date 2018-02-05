defmodule Stats.AdUnitEventAggregator do
  require Logger
  import Stats.AggregatorHelper
  import Ecto.Query, only: [from: 2, where: 3]

  alias Stats.AdUnit
  alias Stats.Campaign
  alias Stats.Repo
  alias Stats.AdUnitEvent
  alias Stats.AdUnitReport
  alias Stats.AdUnitCurrentReport
  alias Stats.Advertiser

  use Timex

  def update_reports_for_ad_units(date) do
    data = get_current_reports()
    default = Stats.AdUnit.event_types

    ad_units = Repo.all(from e in AdUnitCurrentReport, select: [e.content_type, e.size, e.ad_unit_id], distinct: true)
    Enum.each(ad_units, fn ad_unit -> report_for_ad_unit_sizes(ad_unit, data, date, default) end)

    ad_unit_ids = Enum.map(ad_units, fn(ad_unit) -> Enum.take(ad_unit, -1) |> List.first end) |> Enum.uniq
    Enum.each(ad_unit_ids, fn ad_unit_id -> report_for_ad_units(ad_unit_id, data, date, default) end)

    campaign_ids = Repo.all(
      from au in AdUnit,
      where: au.original_id in ^ad_unit_ids,
      select: au.campaign_id,
      distinct: true)
    Enum.each(campaign_ids, fn campaign_id -> report_for_campaigns(campaign_id, data, date, default) end)
  end

  defp report_for_ad_unit_sizes(ad_unit, data, date, default) do
    [content_type, size, ad_unit_id] = ad_unit

    date = transform_date_ad_unit(Repo.get(AdUnit, ad_unit_id), date)

    iteration = fn([category_name, category]) ->
      ad_unit_data = Map.get(data, ad_unit)
      count = if ad_unit_data, do: ad_unit_data.data["#{category_name}"], else: 0
      { category_name,  count }
    end
    event_types = [["impressions",  0], ["clicks", 1], ["swipes", 2], ["5s_views", 3],
                    ["50%_views", 4], ["100%_views", 5], ["submits", 6], ["likes", 7], ["tw_shares", 8],
                    ["fb_shares", 9], ["in_shares", 10], ["wa_shares", 11], ["email_shares", 12]]
    data = Enum.map(event_types, iteration) |> Enum.into(%{})

    {method, changeset} = AdUnitReport.get_or_build_by(
      %{category: AdUnitReport.category(:ad_unit_size), category_id: ad_unit_id, content_type: content_type,
        size: size, date: Date.from(date), data: data})
    apply Repo, method, [changeset]
  end

  defp report_for_ad_units(ad_unit_id, data, date, default) do
    results = calculate_ad_unit_events(ad_unit_id, data, default)

    ad_unit = Repo.get(AdUnit, ad_unit_id)
    date = transform_date_ad_unit(ad_unit, date)

    {method, changeset} = AdUnitReport.get_or_build_by(
      %{category: AdUnitReport.category(:ad_unit), category_id: ad_unit_id,
        date: Date.from(date), data: results})
    apply Repo, method, [changeset]
  end

  defp report_for_campaigns(campaign_id, data, date, default) do
    ad_unit_ids = Repo.all(from au in AdUnit, where: au.campaign_id == ^campaign_id, select: au.original_id)

    results = Enum.reduce(ad_unit_ids, default, fn(ad_unit_id, accumulator) ->
        calculate_ad_unit_events(ad_unit_id, data, accumulator)
    end)

    campaign = Repo.get(Campaign, campaign_id)
    date = transform_date_campaign(campaign, date)

    {method, changeset} = AdUnitReport.get_or_build_by(
      %{category: AdUnitReport.category(:campaign), category_id: campaign_id,
        date: Date.from(date), data: results})
    apply Repo, method, [changeset]
  end

  defp get_current_reports() do
    query = from c in AdUnitCurrentReport, select: {[c.content_type, c.size, c.ad_unit_id], %{content_type: c.content_type, size: c.size, ad_unit_id: c.ad_unit_id, data: c.data}}
    Repo.all(query) |> Enum.into(%{})
  end
end
