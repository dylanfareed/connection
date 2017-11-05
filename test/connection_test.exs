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

    assert Receiver.Service.ping() == ":pong from caller@127.0.0.1"
    assert GenServer.call(Cluster, :ping) == ":pong from receiver1@127.0.0.1"
  end
end
