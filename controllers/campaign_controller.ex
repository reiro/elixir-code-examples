defmodule Stats.CampaignController do
  require Logger
  use Stats.Web, :controller

  alias Stats.Report
  alias Stats.AdUnitReport

  def stats(conn, %{"ids" => ids} = params) do
    Logger.debug "CampaignController.stats"
    {date_start, date_finish} = Stats.ReportHelper.parse_dates(params)
    ids = ids |> Enum.filter(fn (v) -> v != nil && v != "" end)
    get_campaign_stats = fn campaign_id ->
      {campaign_id, _} = Integer.parse(campaign_id)
      report = if (params["source"] == "ad_unit"), do: AdUnitReport, else: Report
      report.get_campaign_stats(campaign_id, date_start, date_finish) |> Map.put("id", campaign_id)
    end
    campaign_stats = Enum.map(ids, get_campaign_stats)
    render(conn, "show.json", campaign_stats: campaign_stats)
  end
end
