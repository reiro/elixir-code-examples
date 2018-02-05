defmodule Stats.ReportHelper do
  use Timex

  def parse_dates(params) do
    {status, val} = Timex.parse(params["date_from"], "{D}-{0M}-{YYYY}")
    date_start = if status == :error do
      :empty
    else
      val |> DateTime.shift(days: -1)
    end

    {status, val} = Timex.parse(params["date_to"], "{D}-{0M}-{YYYY}")
    date_finish = if status == :error do
      :empty
    else
      val
    end

    {date_start, date_finish}
  end
end
