defmodule Engine.AdWeightHelper do
  require Logger
  use Timex

  alias Enzymic.Repo

  def calc_probabilities(ad_ids, user_agent, ip, content_size) do
    if UAInspector.bot?(user_agent) do
     ad_ids
    else
      model = ConCache.get(:engine_cache, "ml_model")
      parsed_agent = UAInspector.parse(user_agent)
      factors = %{}
      factors = Map.put(factors, "device_type", model["device_type"][parsed_agent.device.type])
      factors = Map.put(factors, "os", model["os"][parsed_agent.os.name])
      factors = Map.put(factors, "browser", model["browser"][parsed_agent.client.name])
      factors = Map.put(factors, "ad_unit_size", model["ad_unit_size"][content_size])
      day_of_week = Timex.weekday(Timex.DateTime.today) |> Integer.to_string
      factors = Map.put(factors, "day_of_week", model["day_of_week"][day_of_week])
      hour = Timex.DateTime.now.hour |> Integer.to_string
      factors = Map.put(factors, "hour_of_day", model["hour_of_day"][hour])
      factors = Map.put(factors, "country", model["country"][country(ip)])

      iteration = fn ad_id ->
        ad_vector = model["ad_id"][Integer.to_string(ad_id)]
        weight =
          if ad_vector do
            Enum.map(factors, fn(factor) -> weight(ad_vector[elem(factor, 0)], elem(factor, 1)) end)
              |> Enum.sum
          else
            0
          end
        probability(weight)
      end

      Enum.map(ad_ids, iteration)
    end
  end

  defp country(ip) do
    if ip do
      query = "select country from cidr_to_countries where $1 <<= network"
      Ecto.Adapters.SQL.query!(Repo, query, [%Postgrex.INET{address: ip}]).rows |> List.first |> List.first
    else
      nil
    end
  end

  defp probability(weight) do
    1 / (1 + :math.exp(-weight))
  end

  defp weight(ad_vector, factor_vector) do
    if factor_vector, do: scalar_multiply(ad_vector, factor_vector, 0), else: 0
  end

  defp scalar_multiply([head1 | tail1], [head2 | tail2], accumulator) do
    scalar_multiply(tail1, tail2, head1 * head2 + accumulator)
  end

  defp scalar_multiply([], [], accumulator) do
    accumulator
  end
end
