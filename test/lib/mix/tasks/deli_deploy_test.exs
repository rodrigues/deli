defmodule Mix.DeliDeployTest do
  use DeliCase
  alias Mix.Tasks.Deli.Deploy

  def setup_hosts(env, hosts, tag, setup_mocks? \\ true) do
    stub(HostFilterMock, :hosts, fn ^env, _ -> {:ok, hosts} end)
    stub(VersioningMock, :version_tag, fn nil -> {:ok, tag} end)

    if setup_mocks? do
      for host <- hosts do
        expect(DeployMock, :run, fn ^env, ^host -> :ok end)
      end
    end
  end

  property "deploys application in all default target hosts by default" do
    check all app <- app(),
              env <- env(),
              hosts <- hosts(),
              tag <- version(),
              short? <- boolean() do
      flag = if short?, do: "-y", else: "--yes"
      put_config(:app, app)
      put_config(:default_target, env)
      setup_hosts(env, hosts, tag)

      output =
        capture_io(fn ->
          :ok = Deploy.run([flag])
        end)

      assert output == "version: #{tag}\ndeploy #{app} at #{env}? [Yn] y\n🤞\n"
    end
  end

  property "deploys after confirmation when not passing yes" do
    check all app <- app(),
              env <- env(),
              hosts <- hosts(),
              tag <- version() do
      put_config(:app, app)
      put_config(:default_target, env)
      setup_hosts(env, hosts, tag)

      output =
        capture_io([input: "y\n", capture_prompt: true], fn ->
          :ok = Deploy.run([])
        end)

      assert output == "version: #{tag}\ndeploy #{app} at #{env}? [Yn] 🤞\n"
    end
  end

  property "cancels after denial of confirmation when not passing yes" do
    check all app <- app(),
              env <- env(),
              hosts <- hosts(),
              tag <- version() do
      put_config(:app, app)
      put_config(:default_target, env)
      setup_hosts(env, hosts, tag, false)

      output =
        capture_io([input: "n\n", capture_prompt: true], fn ->
          :ok = Deploy.run([])
        end)

      assert output ==
               "version: #{tag}\ndeploy #{app} at #{env}? [Yn] " <>
                 "\e[32mdeploy cancelled by user\e[0m\n"
    end
  end
end
