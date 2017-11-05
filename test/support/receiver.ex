defmodule Receiver do
  defmodule Service do
    def list_nodes(), do: Node.list

    def ping() do
      ":pong from #{Node.self}"
    end
  end
end
