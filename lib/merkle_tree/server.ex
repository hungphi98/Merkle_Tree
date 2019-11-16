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
    root = Core.build_tree(abs_path, &Crypto.sha256/1)
    {:reply, root}
  end

  def handle_call({:deserialize, root}, _from, state) do

  end

end
