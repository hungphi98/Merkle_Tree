defmodule MerkleTree.Core do
  defstruct [:pieces, :root, :hash_function]

  @number_of_children 2

  @type pieces :: [String.t(), ...]
  @type hash_function :: (String.t() -> String.t())
  @type root :: MerkleTree.Node.t()
  @type t :: %MerkleTree.Core{
    pieces: pieces,
    root: root,
    hash_function: hash_function
  }

  @spec new(pieces, hash_function | Keyword.t()) :: t
  def new(pieces, hash_function \\ nil)
  def new(pieces, hash_function) when is_function(hash_function) do
    new(pieces, hash_function: hash_function)
  end

  @spec serialize(charlist(), hash_function | Keyword.t()) :: root
  def serialize(path, hash_function \\ nil)
  def serialize(path, hash_function) when is_function(hash_function) do
    path
    |> File.ls!
    |> Enum.filter(fn(filename) -> String.match?(filename, ~r/^x/) == true end)
    |> Enum.map(fn(filename) -> File.read!(Path.join(path, filename)) end)
    |> build(hash_function)
  end

  @spec build(pieces, hash_function | Keyword.t()) :: root

  def build(pieces, hash_function \\ nil)

  def build(pieces, hash_function) when is_function(hash_function) do
    leaves = Enum.map(pieces, fn(piece) ->
      %MerkleTree.Node{
        value: hash_function.(piece),
        data: piece,
        children: []
        }
      end)
    IO.inspect(leaves)
    build_tree(leaves, hash_function)
  end

  @spec build_tree(pieces, hash_function | Keyword.t()) :: t
  def build_tree([root], _), do: root
  def build_tree(nodes, hash_function) do
    children_partitions = Enum.chunk_every(nodes, @number_of_children)
    parents = Enum.map(children_partitions, fn(partition)->
      concat = partition
      |> Enum.map(&(&1.value))
      |> Enum.reduce("", fn(acc, x) -> acc <> x end)
      %MerkleTree.Node{
        value: hash_function.(concat),
        children: partition,
      }
    end)
    build_tree(parents, hash_function)
  end

  @spec deserialize(charlist(), root) :: IO
  def deserialize(path, root) do
    content = reconstruct([root])
    |> Enum.join()
    File.write(path, content)
  end

  @spec reconstruct([root]) :: [charlist()]
  def reconstruct([]), do: []
  def reconstruct([%MerkleTree.Node{:data => data} | tail]) do
    [data | reconstruct(tail)]
  end
  def reconstruct([%MerkleTree.Node{:children => children} | tail]) do
    reconstruct(children++tail)
  end

end
