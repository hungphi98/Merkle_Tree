defmodule MerkleTree.Sync do
  alias MerkleTree.{Core, Crypto, Node}

  @type pieces :: [String.t(), ...]
  @type hash_function :: (String.t() -> String.t())
  @type root :: MerkleTree.Node.t()
  @type t :: %MerkleTree.Core{
    pieces: pieces,
    root: root,
    hash_function: hash_function
  }

  @spec verify(root, root) :: Boolean
  def verify(%Node{:value => value1},
             %Node{:value => value2}), do: value1 == value2

  @spec verify(charlist(), charlist()) :: Boolean
  def verify(dir_1, dir_2), do: dir_1 == dir_2

  @spec synchronize(root, root) :: root
  def synchronize(%Node{:children => []}, root2), do: root2
  def synchronize(%Node{:children => [left1 | [right1]]}, root2) do
    [left2| [right2]] = root2.children
    if left1.value != left2.value do
      if right1.value != right2.value do
        root2
      else
        synchronize(left1, left2)
      end
    else
      if right1.value != right2.value do
        synchronize(right1, right2)
      end
    end
  end
end
