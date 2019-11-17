defmodule MerkleTree.Server do

  alias MerkleTree.{Core, Crypto}
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_args) do
    {:ok, nil}
  end

  def handle_call({:serialize, path}, _from, state) do
    abs_path =
      path
      |> Path.expand(__DIR__)
    root = Core.serialize(abs_path, &Crypto.sha256/1)
    {:reply, root, state}
  end

  def handle_call({:deserialize, path, root}, _from, state) do
    path
    |> Path.expand(__DIR__)
    |> Core.deserialize(root)
    {:reply, nil, state}
  end

end
