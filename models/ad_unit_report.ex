defmodule Stats.AdUnitReport do
  require Logger
  use Stats.Web, :model

  import Ecto.Query
  alias Stats.Repo
  require Stats.AdUnit

  schema "ad_unit_reports" do
    field :category, :integer
    field :category_id, :integer
    field :content_type, :integer
    field :size, :integer
    field :date, Timex.Ecto.Date
    field :data, :map

    timestamps
  end

  def category(type), do: %{ ad_unit_size: 0, ad_unit: 1, campaign: 2}[type]

  @required_fields ~w(category category_id date data)
  @optional_fields ~w(content_type size)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def get_or_build_by(params) do
    report_params = %{ category_id: params[:category_id], category: params[:category], date: params[:date] }
    if Map.has_key?(params, :content_type) do
      report_params = Map.merge(report_params, %{ content_type: params[:content_type], size: params[:size] })
    end
    case Stats.AdUnitReport
      |> Stats.Repo.get_by(report_params) do
        nil ->
          {:insert, changeset(struct(Stats.AdUnitReport, %{}), params)}
        report ->
          {:update, changeset(report, params)}
    end
  end

  def get_campaign_stats(campaign_id, date_start \\ :empty, date_finish \\ :empty) do
    get_stats(category(:campaign), campaign_id, date_start, date_finish)
  end

  def get_ad_unit_stats(ad_unit_id, date_start \\ :empty, date_finish \\ :empty) do
    get_stats(category(:ad_unit), ad_unit_id, date_start, date_finish)
  end

  def get_ad_unit_size_stats(ad_unit_id, date_start \\ :empty, date_finish \\ :empty) do
    ad_units = Repo.all(from r in Stats.AdUnitReport,
      where: r.category_id == ^ad_unit_id and
        r.category == ^category(:ad_unit_size),
      select: [r.content_type, r.size, r.category_id], distinct: true)
    Enum.map(ad_units, fn ad_unit ->
      [content_type, size, _] = ad_unit
      get_stats(category(:ad_unit_size), ad_unit_id, date_start, date_finish, content_type, size)
       |> Map.put("content_type", content_type)
       |> Map.put("size", size)
    end)
  end

  defp get_stats(category, category_id, date_start, date_finish, content_type \\ nil, size \\ nil) do
    query = if category == category(:ad_unit_size) do
      Stats.AdUnitReport |> where([r], r.category == ^category and
        r.category_id == ^category_id and
        r.content_type == ^content_type and
        r.size == ^size)
    else
      Stats.AdUnitReport |> where([r], r.category == ^category and r.category_id == ^category_id)
    end
    query = query |> order_by(desc: :date) |> limit(1)

    case {date_start, date_finish} do
      {:empty, :empty} ->
        (Repo.one(query) || default).data
      {date_start, :empty} ->
        query_start = query |> where([r], r.date <= ^date_start)
        report1 = Repo.one(query_start) || default
        report2 = Repo.one(query) || default
        diff(report1, report2)
      {:empty, date_finish} ->
        query_finish = query |> where([r], r.date <= ^date_finish)
        (Repo.one(query_finish) || default).data
      {date_start, date_finish} ->
      query_start = query |> where([r], r.date <= ^date_start)
        query_finish = query |> where([r], r.date <= ^date_finish)
        report1 = Repo.one(query_start) || default
        report2 = Repo.one(query_finish) || default
        diff(report1, report2)
    end
  end

  defp diff(report1, report2) do
    Enum.map(Map.keys(report1.data), fn key -> {key, report2.data[key] - report1.data[key]} end) |> Enum.into(%{})
  end

  defp default do
    struct(Stats.AdUnitReport, %{data: Stats.AdUnit.event_types})
  end
end
