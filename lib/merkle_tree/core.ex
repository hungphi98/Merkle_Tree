defmodule MerkleTree.Core do
  alias MerkleTree.Node
  defstruct [:pieces, :root, :hash_function]

  @type pieces :: [String.t(), ...]
  @type hash_function :: (String.t() -> String.t())
  @type root :: MerkleTree.Node.t()
  @type t :: %MerkleTree.Core{
    pieces: pieces,
    root: root,
    hash_function: hash_function
  }

end
