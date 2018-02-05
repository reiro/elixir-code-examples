defmodule Stats.AdController do
  require Logger
  use Stats.Web, :controller

  alias Stats.Report

  def stats(conn, %{"ids" => ids} = params) do
    Logger.debug "AdController.stats"
    {date_start, date_finish} = Stats.ReportHelper.parse_dates(params)
    ids = ids |> Enum.filter(fn (v) -> v != nil && v != "" end)
    get_ad_stats = fn ad_id ->
      {ad_id, _} = Integer.parse(ad_id)
      Report.get_ad_stats(ad_id, date_start, date_finish) |> Map.put("id", ad_id)
    end
    ad_stats = Enum.map(ids, get_ad_stats)

    render(conn, "show.json", ad_stats: ad_stats)
  end
end
