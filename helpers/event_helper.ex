defmodule Stats.EventHelper do
  def calculate_client_uid(data) do
    fields = [
      data["user_agent"] || '',
      data["ip"] || '',
      data["ad_unit_size"],
      data["plugins_hash"] || '',
      data["domain_url"] || ''
    ]
    :crypto.hash(:sha, fields)
      |> Base.encode16
  end

  def should_save_event?(event_params) do
    if Map.has_key?(event_params, "client_data") do
      ua = event_params["client_data"]["user_agent"]
      !Browser.bot?(ua) and Browser.known?(ua) and !Browser.search_engine?(ua) and !Browser.phantom_js?(ua)
    else
      false
    end
  end
end
