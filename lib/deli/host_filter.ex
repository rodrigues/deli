defmodule Deli.HostFilter do
  import Deli.Shell
  alias Deli.Config

  @moduledoc false

  def hosts(env, args, silent? \\ false) do
    hosts = env |> Config.hosts()

    with %Regex{} = exp <- args |> host_filter do
      with [_ | _] = filtered_hosts <- hosts |> Enum.filter(&(&1 =~ exp)) do
        unless silent?, do: list_hosts(filtered_hosts)
        {:ok, filtered_hosts}
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
            {:ok, hosts}
        end
    end
  end

  def host(env, args) do
    {:ok, hosts} = env |> hosts(args, true)
    length = hosts |> Enum.count()

    case length do
      0 ->
        {:error, :no_host_found}

      1 ->
        host = hosts |> Enum.at(0)
        {:ok, host}

      _ ->
        hosts |> select_host
    end
  end

  defp select_host(hosts) do
    hosts |> Enum.with_index() |> Enum.each(&print_host_option/1)
    count = hosts |> Enum.count()

    {number, ""} =
      "Choose a number:"
      |> Mix.shell().prompt()
      |> String.trim()
      |> Integer.parse()

    if number < count do
      host = hosts |> Enum.at(number)
      {:ok, host}
    else
      select_host(hosts)
    end
  end

  defp print_host_option({host, index}) do
    IO.puts([
      IO.ANSI.bright(),
      "[#{index}] ",
      IO.ANSI.reset(),
      IO.ANSI.yellow(),
      host,
      IO.ANSI.reset()
    ])
  end

  defp host_filter(args) do
    filter =
      args
      |> OptionParser.parse(aliases: [h: :host], switches: [host: :string])
      |> elem(0)
      |> Keyword.get(:host)

    if filter, do: ~r/#{filter}/
  end

  defp list_hosts(hosts) do
    IO.puts(hosts_line(hosts))
  end

  defp hosts_line(hosts) do
    list = hosts |> Enum.map(&"## #{&1}") |> Enum.join("\n")
    "# hosts\n#{list}"
  end
end