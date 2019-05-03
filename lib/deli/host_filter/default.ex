defmodule Deli.HostFilter.Default do
  import Deli, only: [is_env: 1, is_host: 1]
  import Deli.Config.Ensure, only: [ensure_binary: 1]
  import Deli.Shell, only: [error!: 1]
  alias Deli.Config

  @moduledoc false

  @behaviour Deli.HostFilter

  @impl true
  def hosts(env, args, silent? \\ false)
      when is_env(env) and is_list(args) and is_boolean(silent?) do
    hosts = Config.host_provider().hosts(env)

    with %Regex{} = exp <- host_filter(args) do
      with [_ | _] = filtered_hosts <- Enum.filter(hosts, &(&1 =~ exp)) do
        unless silent?, do: list_hosts(filtered_hosts)
        {:ok, Enum.map(filtered_hosts, &ensure_binary/1)}
      else
        [] ->
          error!("""
          Host filter #{inspect(exp)} excluded all hosts!
          #{hosts_line(hosts)}
          """)
      end
    else
      nil ->
        case hosts do
          [] ->
            error!("No hosts defined for target #{env}")

          _ ->
            unless silent?, do: list_hosts(hosts)
            {:ok, Enum.map(hosts, &ensure_binary/1)}
        end
    end
  end

  @impl true
  def host(env, args) when is_env(env) and is_list(args) do
    {:ok, hosts} = hosts(env, args, true)
    length = Enum.count(hosts)

    case length do
      0 ->
        {:error, :no_host_found}

      1 ->
        host = hosts |> Enum.at(0) |> ensure_binary
        {:ok, host}

      _ ->
        select_host(hosts)
    end
  end

  defp select_host(hosts) when is_list(hosts) do
    hosts |> Enum.with_index() |> Enum.each(&print_host_option/1)
    count = Enum.count(hosts)

    {number, ""} =
      "Choose a number:"
      |> Mix.shell().prompt()
      |> String.trim()
      |> Integer.parse()

    if number < count do
      host = hosts |> Enum.at(number) |> ensure_binary
      {:ok, host}
    else
      select_host(hosts)
    end
  end

  defp print_host_option({host, index})
       when is_host(host) and is_integer(index) do
    IO.puts([
      IO.ANSI.bright(),
      "[#{index}] ",
      IO.ANSI.reset(),
      IO.ANSI.yellow(),
      host,
      IO.ANSI.reset()
    ])
  end

  defp host_filter(args) when is_list(args) do
    filter =
      args
      |> OptionParser.parse(aliases: [h: :host], switches: [host: :string])
      |> elem(0)
      |> Keyword.get(:host)

    if filter, do: ~r/#{filter}/
  end

  defp list_hosts(hosts) when is_list(hosts) do
    IO.puts(hosts_line(hosts))
  end

  defp hosts_line(hosts) when is_list(hosts) do
    list = hosts |> Enum.map(&"## #{&1}") |> Enum.join("\n")
    "# hosts\n#{list}"
  end
end
