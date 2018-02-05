defmodule Elcron.MlModelLoader do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    load_and_cache_model
    schedule_task
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Do the work you desire here
    load_and_cache_model
    schedule_task # Reschedule once more
    {:noreply, state}
  end

  defp schedule_task do
    Process.send_after(self(), :work, 24 * 60 * 60 * 1000) # In 1 day
  end

  defp load_and_cache_model do
    {_, json} = File.read(Application.get_env(:enzymic, :ml_model_path))
    {_, model} = JSON.decode(json)
    ConCache.put(:engine_cache, "ml_model", model)
  end
end
