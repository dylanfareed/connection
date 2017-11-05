defmodule ConnectionTest do
  use ExUnit.Case

  test "spawns connected receiver nodes"do
    Cluster.start_link(3)
    assert Node.self == :"caller@127.0.0.1"
    assert Receiver.Service.list_nodes() == [:"receiver1@127.0.0.1", :"receiver2@127.0.0.1", :"receiver3@127.0.0.1"]
    Cluster.stop()
  end

  test "connects receiver nodes to caller"do
    Cluster.start_link(1)
    assert GenServer.call(Cluster, :list_nodes) == [:"caller@127.0.0.1"]
    Cluster.stop()
  end

  test "can execute code on connected nodes"do
    Cluster.start_link(2)
    assert Node.self == :"caller@127.0.0.1"

    assert Receiver.Service.ping() == ":pong from caller@127.0.0.1"
    assert GenServer.call(Cluster, :ping) =~ ":pong from receiver"
    Cluster.stop()
  end
end
