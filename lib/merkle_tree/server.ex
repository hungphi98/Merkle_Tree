defmodule MerkleTree.Server do

  alias MerkleTree.{Crypto, Serializer}
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
    root = Serializer.serialize(abs_path, &Crypto.sha256/1)
    {:reply, root, state}
  end

  def handle_call({:deserialize, path}, _from, state) do
    path
    |> Path.expand(__DIR__)
    |> Serializer.deserialize
    {:reply, nil, state}
  end

end
