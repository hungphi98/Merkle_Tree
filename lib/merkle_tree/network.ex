defmodule MerkleTree.Network do

  alias MerkleTree.{Core, Crypto}
  def send_tree_copy(receiver_id, root) do
    send receiver_id, {:ok, self, root}
  end

  def listen do
    receive do
      {:ok, sender_id, root} ->
        IO.inspect(root)
    end
    listen
  end
end
