defmodule WRandom.WRandom do
  def uniform(weights_list) do
    weight_cumulative = normalize(weights_list)
    weight_cumulative = Enum.scan(weight_cumulative, 0, &(&1 + &2))
    rnd = :random.uniform
    Enum.find_index(weight_cumulative, fn(i) -> rnd <= i end)
  end

  def shuffle(enumerable, weights_list) do
    :random.seed(:erlang.system_time) # setup random
    do_shuffle(enumerable, weights_list, [], Enum.count(enumerable))
  end

  defp do_shuffle(enumerable, _, shuffled, count) when count == 1 do
    shuffled |> List.insert_at(-1, List.first(enumerable))
  end

  defp do_shuffle(enumerable, weights_list, shuffled, count) do
    index = uniform(weights_list)
    shuffled = shuffled |> List.insert_at(-1, Enum.at(enumerable, index))
    do_shuffle(List.delete_at(enumerable, index), List.delete_at(weights_list, index), shuffled, count - 1)
  end

  defp normalize(weights_list) do
    total = Enum.sum(weights_list)
    Enum.map(weights_list, fn item -> item / total end)
  end
end