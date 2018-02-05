defmodule Stats.EventController do
  require Logger
  use Stats.Web, :controller

  import Ecto.Query
  alias Stats.Event
  alias Stats.CurrentReport
  alias Stats.AdUnitCurrentReport
  alias Stats.Repo

  plug :scrub_params, "event" when action in [:create]

  def create(conn, %{"event" => event_params}) do
    Logger.debug "EventController.create"
    params = if Map.has_key?(event_params, "client_data") do
      Map.merge(event_params, %{"client_uid" => Stats.EventHelper.calculate_client_uid(event_params["client_data"])})
    else
      event_params
    end

    changeset = Event.changeset(%Event{}, params)
    if Stats.EventHelper.should_save_event?(event_params), do: Repo.insert(changeset)
    text conn, :ok
  end

  def unlike(conn, %{"unlike" => unlike_params}) do
    current_report = Stats.CurrentReport |> Repo.get_by(ad_id: unlike_params["ad_id"])
    new_data = Map.update(current_report.data, "likes", 0,  &(&1 - 1))
    changeset = Stats.CurrentReport.changeset(current_report, %{data: new_data})
    Repo.update(changeset)

    ad_unit_current_report = Stats.AdUnitCurrentReport
                            |> Stats.Repo.get_by(ad_unit_id: unlike_params["ad_unit_id"],
                                           content_type: unlike_params["content_type"],
                                           size: unlike_params["size"])
    new_data = Map.update(ad_unit_current_report.data, "likes", 0,  &(&1 - 1))
    changeset = Stats.AdUnitCurrentReport.changeset(ad_unit_current_report, %{data: new_data})
    Repo.update(changeset)

    text conn, :ok
  end
end
