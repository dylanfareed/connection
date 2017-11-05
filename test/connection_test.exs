defmodule ConnectionTest do
  use ExUnit.Case

  setup do
    Cluster.start_link(1)
    :ok
  end

  test "can execute code on connected nodes"do
    assert Node.self == :"caller@127.0.0.1"

    assert Receiver.Service.list_nodes() == [:"receiver1@127.0.0.1"]
    assert GenServer.call(Cluster, :list_nodes) == [:"caller@127.0.0.1"]

    assert Receiver.Service.ping() == "Hello from caller@127.0.0.1"
    assert GenServer.call(Cluster, :ping) == "Hello from receiver1@127.0.0.1"
  end
end
