defmodule AutoOptimization.MultyArmedBandit do
  alias Statistics.Distributions.Beta

  # https://sudeepraja.github.io/Bandits/
  # Thompson Sampling Strategy
  def thompson_sampling_strategy(ads, ads_count_limit) do
    :random.seed(:erlang.now())
    ads_count = length(ads)
    prior = Enum.map(0..ads_count - 1, fn(x) -> [1, 1] end)

    beta_calc = fn(i) ->
      ad_id = Enum.at(ads, i) |> Enum.at(0)
      ad_data = Enum.at(ads, i) |> Enum.at(1)
      successes = ad_data["clicks"] + ad_data["100%_views"] / 100
      ad_prior = prior |> Enum.at(i)

      # if ad is new, first show with high probability
      if successes < 100 && ad_data["impressions"] < 10000 do
        a = 1
      else
        a = Enum.at(ad_prior, 0) + successes
        b = Enum.at(ad_prior, 1) + ad_data["impressions"] - successes
        a = a / (b / 10)
      end

      {ad_id, Statistics.Distributions.Beta.rand(a, 10)}
    end

    Enum.map(0..ads_count - 1, beta_calc) |>
    Enum.sort_by(fn({id, weight}) -> -weight end) |>
    Enum.map(fn({id, weight}) -> id end) |>
    Enum.slice(0..ads_count_limit - 1)
  end
end
