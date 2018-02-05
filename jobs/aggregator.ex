defmodule Stats.Aggregator do
  import Stats.AdEventAggregator
  import Stats.AdUnitEventAggregator

  use Timex

  def process(date \\ DateTime.now) do
    update_reports(date)
    update_reports_for_ad_units(date)
  end
end
