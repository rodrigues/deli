defmodule Deli.HostFilter do
  import Deli.Shell
  import Deli.Config.Ensure
  alias Deli.Config

  @moduledoc false

  @spec hosts(Deli.env(), OptionParser.argv(), boolean) :: {:ok, [Deli.host()]}
  def hosts(env, args, silent? \\ false)
      when is_atom(env) and is_list(args) and is_boolean(silent?) do
    hosts = env |> Config.host_provider().hosts()

    with %Regex{} = exp <- args |> host_filter do
      with [_ | _] = filtered_hosts <- hosts |> Enum.filter(&(&1 =~ exp)) do
        unless silent?, do: list_hosts(filtered_hosts)
        {:ok, filtered_hosts |> Enum.map(&ensure_binary/1)}
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
            {:ok, hosts |> Enum.map(&ensure_binary/1)}
        end
    end
  end

  @spec host(Deli.env(), OptionParser.argv()) :: {:ok, Deli.host()} | {:error, term}
  def host(env, args) when is_atom(env) and is_list(args) do
    {:ok, hosts} = env |> hosts(args, true)
    length = hosts |> Enum.count()

    case length do
      0 ->
        {:error, :no_host_found}

      1 ->
        host = hosts |> Enum.at(0) |> ensure_binary
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
      host = hosts |> Enum.at(number) |> ensure_binary
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

  @spec host_filter(OptionParser.argv()) :: Regex.t() | nil
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
