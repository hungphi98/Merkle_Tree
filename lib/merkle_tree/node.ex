defmodule MerkleTree.Node do

  defstruct [:value, :data, :children]

  @type hash :: binary() | String.t()

  @type data :: String.t() | nil

  @type t :: %__MODULE__{
    value: hash(),
    data: data,
    children: [MerkleTree.Node.t()],
  }
end
