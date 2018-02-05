defmodule Stats.AdEventAggregator do
  require Logger
  import Stats.AggregatorHelper
  import Ecto.Query, only: [from: 2, where: 3]

  alias Stats.Event
  alias Stats.AdUnit
  alias Stats.Campaign
  alias Stats.Report
  alias Stats.Repo
  alias Stats.CurrentReport

  use Timex

  def update_reports(date) do
    ad_ids = Repo.all(from c in CurrentReport, select: c.ad_id, distinct: true)
    ad_unit_ids = Repo.all(from au in AdUnit, where: fragment("? && ?", au.ads, ^ad_ids), select: au.id, distinct: true)
    campaign_ids = Repo.all(from au in AdUnit, where: au.id in ^ad_unit_ids, select: au.campaign_id, distinct: true)

    # Count events for each ad_id
    data = get_current_reports()
    default = Stats.AdUnit.event_types

    # Process ads
    Enum.each(ad_ids, fn ad_id -> ad_report(ad_id, data, date) end)

    # Process ad units
    ad_units = AdUnit |> where([a], a.id in ^ad_unit_ids) |> Repo.all |> Repo.preload([:campaign])
    Enum.each(ad_units, fn ad_unit -> ad_unit_report(ad_unit, data, date, default) end)

    # Process campaign
    campaigns = Campaign |> where([c], c.original_id in ^campaign_ids) |> Repo.all
    Enum.each(campaigns, fn campaign -> campaign_report(campaign, data, date, default) end)
  end

  defp campaign_report(campaign, data, date \\ DateTime.now, default) do
    date = transform_date_campaign(campaign, date)

    ads = Enum.map((campaign |> Repo.preload(:ad_units)).ad_units, fn ad_unit -> ad_unit.ads end) |> List.flatten
    results = calculate_ad_events(ads, data, default)
    {method, changeset} = Report.get_or_build_by(%{"category" => "campaign", "category_id" => campaign.original_id, "date" => Date.from(date), "data" => results})
    apply Repo, method, [changeset]
  end

  defp ad_unit_report(ad_unit, data, date \\ DateTime.now, default) do
    date = transform_date_ad_unit(ad_unit, date)

    results = calculate_ad_events(ad_unit.ads, data, default)
    {method, changeset} = Report.get_or_build_by(%{"category" => "ad_unit", "category_id" => ad_unit.original_id, "date" => Date.from(date), "data" => results})
    apply Repo, method, [changeset]
  end

  defp ad_report(ad_id, data, date \\ DateTime.now) do
    ad_unit = Repo.one(from au in AdUnit, where: fragment("? && ?", au.ads, ^[ad_id]))
    date = transform_date_ad_unit(ad_unit, date)

    results = Map.get(data, ad_id)
    {method, changeset} = Report.get_or_build_by(%{"category" => "ad", "category_id" => ad_id, "date" => Date.from(date), "data" => results})
    apply Repo, method, [changeset]
  end

  defp get_current_reports() do
    query = from c in CurrentReport,
            select: {c.ad_id, c.data},
            order_by: c.ad_id
    Repo.all(query) |> Enum.into(%{})
  end
end
