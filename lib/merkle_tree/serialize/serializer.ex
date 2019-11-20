defmodule MerkleTree.Serializer do
  alias MerkleTree.{Node, FileHierarchy, Crypto, Core, Utilities}

  @number_of_children 2
  @type pieces :: [String.t(), ...]
  @type hash_function :: (String.t() -> String.t())
  @type root :: MerkleTree.Node.t()
  @type t :: %MerkleTree.Core{
    pieces: pieces,
    root: root,
    hash_function: hash_function
  }


  @spec serialize(charlist(), hash_function | Keyword.t()) :: root
  def serialize(path, hash_function \\ nil)
  def serialize(path, hash_function) when is_function(hash_function) do
    prefix = Utilities.get_prefix(path)

    System.cmd("mkdir", [prefix])
    System.cmd("gsplit", ["-b", "10KB", path, prefix <> "/x"])

    root = prefix
      |> File.ls!
      |> Enum.filter(fn(filename) -> String.match?(filename, ~r/^x/) == true end)
      |> Enum.sort()
      |> Enum.map(fn(filename) -> {filename, File.read!(Path.join(prefix, filename))} end)
      |> build(hash_function)

    System.cmd("find", [prefix <> "/", "-name", "x*[a-z]*", "-delete"])
    FileHierarchy.file_hierarchy(root, prefix)
    root
  end

  @spec build(pieces, hash_function | Keyword.t()) :: root
  def build(pieces, hash_function \\ nil)
  def build(pieces, hash_function) when is_function(hash_function) do
    leaves = Enum.map(pieces, fn({filename, piece}) ->
      %Node{
        value: filename,
        data: piece,
        children: []
        }
      end)
    leaves
    |> build_immediate_parents_from_children(hash_function)
    |> build_tree(hash_function)
  end

  def build_immediate_parents_from_children(nodes, hash_function) do
    children_partitions = Enum.chunk_every(nodes, @number_of_children)
    parents = Enum.map(children_partitions, fn(partition)->
      concat = partition
      |> Enum.map(&(&1.data))
      |> Enum.reduce("", fn(acc, x) -> acc <> x end)
      %Node{
        value: hash_function.(concat),
        children: partition,
      }
    end)
    parents
  end

  @spec build_tree(pieces, hash_function | Keyword.t()) :: t
  def build_tree([root], _), do: root
  def build_tree(nodes, hash_function) do
    children_partitions = Enum.chunk_every(nodes, @number_of_children)
    parents = Enum.map(children_partitions, fn(partition)->
      concat = partition
      |> Enum.map(&(&1.value))
      |> Enum.reduce("", fn(acc, x) -> acc <> x end)
      %Node{
        value: hash_function.(concat),
        children: partition,
      }
    end)
    build_tree(parents, hash_function)
  end

  @spec deserialize(charlist()) :: IO
  def deserialize(path) do
    content =
      path
      |> Utilities.get_prefix
      |> FileHierarchy.construct_tree_from_directories
      |> reconstruct()
      |> Enum.sort_by(fn({filename, data}) -> filename end)
      |> Enum.map(fn({filename,  data}) -> data end)
      |> Enum.join()
    file_name = path |> Utilities.get_file_name
    path
    |> Utilities.get_enclosing_folder
    |> Utilities.path_to_file("new_#{file_name}")
    |> File.write(content)
  end

  @spec reconstruct(root) :: [charlist()]
  def reconstruct(root), do: _reconstruct([root])

  defp _reconstruct([]), do: []
  defp _reconstruct([%Node{:children => children, :data => nil} | tail]) do
    _reconstruct(children++tail)
  end
  defp _reconstruct([%Node{:data => data, :value => filename} | tail]) do
    [{filename, data} | _reconstruct(tail)]
  end
end
