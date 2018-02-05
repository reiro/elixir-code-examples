defmodule Enzymic.AdUnitController do
  require Logger
  use Enzymic.Web, :controller

  import Engine.AdWeightHelper
  import Ecto.Query

  alias Enzymic.AdUnit
  alias Enzymic.CurrentReport
  alias Enzymic.AdUnitEvent
  alias Enzymic.StatsRepo

  use Timex

  @single_ad_unit_type 3
  @infini_video_size 0
  @imp_limit 10_000
  @clicks_limit 10
  @views_coeff 100

  def show(conn, %{"id" => id}) do
    # Init Hashids
    hashids = Hashids.new(salt: Application.get_env(:enzymic, :salt), min_len: 16)

    # Decode encrypted numbers
    numbers = Hashids.decode!(hashids, id)

    # Get ad unit
    ad_unit = numbers
      |> List.first
      |> (&Repo.get!(AdUnit, &1)).()

    # Get ad unit type
    [_head | tail] = numbers
    # For tags version 1.0
    if length(tail) == 0, do: tail = [0, 0]
    ad_unit_type = List.first(tail)

    # Get ad unit size
    ad_unit_size = List.last(tail)

    # Get ads
    ad_ids =
      from(a in Enzymic.Ad,
        select: a.id,
        where: a.ad_unit_id == ^ad_unit.id,
        where: a.status == 0) |> Repo.all

    # Get not infini video ads
    if ad_unit_type == @single_ad_unit_type && ad_unit_size != @infini_video_size do
      not_infini_ads =
        from(a in Enzymic.Ad,
          select: a.id,
          join: v in assoc(a, :video),
          where: a.ad_unit_id == ^ad_unit.id,
          where: a.status == 0,
          where: v.video_type == 2) |> Repo.all

      ad_ids = ad_ids -- not_infini_ads
    end

    # Collect statistics for ad unit for 1 day for optimization algorithm for optimized rotation
    collect_stats = Timex.DateTime.from(:calendar.universal_time()) |> Timex.after?(Timex.shift(ad_unit.created_at, days: 1))

    ads_count = elem(Enzymic.AdUnit.ads_count(ad_unit), ad_unit_type)
      |> elem(ad_unit_size)

    ad_ids =
      cond do
        !(ad_unit.auto_optimization or ad_unit.sequence) or (ad_unit.auto_optimization and !collect_stats) == true ->
          ad_ids |> Enum.take_random(ads_count)
        ad_unit.auto_optimization and collect_stats == true ->
          ads = from(c in Enzymic.CurrentReport,
                    select: [c.ad_id, c.data],
                    where: c.ad_id in ^ad_ids) |>
                    Enzymic.StatsRepo.all
          AutoOptimization.MultyArmedBandit.thompson_sampling_strategy(ads, ads_count)
        ad_unit.sequence == true ->
          ad_ids = ad_unit.sequence_ids
            |> Enum.take(ads_count)
            |> Enum.map(&(String.to_integer(&1)))
      end

    # Generate link to static
    link_to_ads = ad_ids
            |> List.insert_at(-1, ad_unit_size)
            |> List.insert_at(-1, ad_unit.id)
            |> (&Hashids.encode(hashids, &1)).()
            |> (&("#{Application.get_env(:enzymic, :static_url)}#{&1}")).()

    # parse user agent and IP
    user_agent = Plug.Conn.get_req_header(conn, "user-agent") |> List.first
    ip = Plug.Conn.get_req_header(conn, "x-forwarded-for")
      |> List.first

    conn = fetch_cookies(conn)
    cookies = conn.cookies
                |> Enum.reduce([], fn ({key, val}, acc) -> ["#{key}=#{val}"] ++ acc end)
                |> Enum.join("; ")
    client_data = %{"ad_unit_id" => ad_unit.id, "ad_unit_size" => ad_unit_size, "user_agent" => user_agent, "ip" => ip, "cookies" => cookies}
    event_params = %{"ad_unit_id" => ad_unit.id, "category" => 0, "size" => ad_unit_size, "content_type" => ad_unit_type, "ad_id" => 0, "client_data" => client_data}

    params = Map.merge(event_params, %{"client_uid" => Enzymic.EventHelper.calculate_client_uid(client_data)})
    changeset = Enzymic.AdUnitEvent.changeset(%Enzymic.AdUnitEvent{}, params)
    Enzymic.StatsRepo.insert(changeset)

    # Render link to static
    text(conn, link_to_ads)
  end

  def index(conn, %{}) do
    link_to_ads = Application.get_env(:enzymic, :lead_gen_url)
    text(conn, link_to_ads)
  end
end
