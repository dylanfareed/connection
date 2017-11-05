defmodule Cluster do
  @moduledoc false

  use GenServer

  @timeout 5_000
  @master "caller"
  @slave "receiver"
  @host "127.0.0.1"
  @service_module Receiver.Service

  def start_link(count) do
    GenServer.start_link(__MODULE__, [count: count], name: __MODULE__)
  end

  def stop(), do: GenServer.stop(__MODULE__)

  def init(count: count) do
    spawn_master()
    spawn_slaves(count)
    {:ok, %{}}
  end

  def terminate(_reason, _state) do
    Enum.map(Node.list(), &:slave.stop/1)
    :net_kernel.stop()
  end

  def handle_call(:list_nodes, _from, state) do
    results = rpc(random_member(), @service_module, :list_nodes, [])
    {:reply, results, state}
  end

  def handle_call(:ping, _from, state) do
    results = rpc(random_member(), @service_module, :ping, [])
    {:reply, results, state}
  end

  defp spawn_master() do
    :net_kernel.start([:"#{@master}@127.0.0.1"])
    :erl_boot_server.start([])
    allow_boot(~c"#{@host}")
  end

  defp spawn_slaves(count) do
    1..count
    |> Stream.map(fn index -> ~c"#{@slave}#{index}@#{@host}" end)
    |> Stream.map(&Task.async(fn -> spawn_slave(&1) end))
    |> Stream.map(&Task.await(&1, @timeout))
    |> Enum.to_list
  end

  defp spawn_slave(node_host) do
    with {:ok, node} <- :slave.start(~c"#{@host}", node_name(node_host), inet_loader_args()) do
      add_code_paths(node)
      {:ok, node}
    end
  end

  defp rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end

  defp inet_loader_args do
    ~c"-loader inet -hosts #{@host} -setcookie #{:erlang.get_cookie()}"
  end

  defp allow_boot(host) do
    with {:ok, ipv4} <- :inet.parse_ipv4_address(host),
      do: :erl_boot_server.add_slave(ipv4)
  end

  defp add_code_paths(node) do
    rpc(node, :code, :add_paths, [:code.get_path()])
  end

  defp node_name(node_host) do
    node_host
    |> to_string()
    |> String.split("@")
    |> Enum.at(0)
    |> String.to_atom()
  end

  defp random_member(), do: Node.list() |> Enum.random
end
