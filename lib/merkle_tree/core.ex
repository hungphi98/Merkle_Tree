defmodule MerkleTree.Core do
  alias MerkleTree.Node
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

  @spec serialize(charlist(), hash_function | Keyword.t()) :: root
  def serialize(path, hash_function \\ nil)
  def serialize(path, hash_function) when is_function(hash_function) do
    file_name =
      path
      |> Path.split
      |> Enum.at(-1)

    tmp =
      path
      |> Path.split()
      |> Enum.drop(-1)
      |> Path.join()

    prefix = tmp <> "/_#{file_name}"

    System.cmd("mkdir", [prefix])
    System.cmd("gsplit", ["-b", "10KB", path, prefix <> "/x"])

    root = prefix
      |> File.ls!
      |> Enum.filter(fn(filename) -> String.match?(filename, ~r/^x/) == true end)
      |> Enum.sort()
      |> Enum.map(fn(filename) -> File.read!(Path.join(prefix, filename)) end)
      |> build(hash_function)

    System.cmd("find", [prefix <> "/", "-name", "x*[a-z]*", "-delete"])
    file_hierarchy(root, prefix)
    root
  end

  @spec file_hierarchy(root, charlist()) :: nil
  def file_hierarchy(root \\ nil, path)
  def file_hierarchy(%Node{:children => [], :data => data, :value => filename}, path) do
    File.write(path <> "/#{filename}", data)
  end
  def file_hierarchy(%Node{:children => [left| []], :value => value}, path) do
    new_path = path <> "/#{value}"
    System.cmd("mkdir", [new_path])
    file_hierarchy(left, path)
  end
  def file_hierarchy(%Node{:children => [left | [right]], :value => value}, path) do
    new_path = path <> "/#{value}"
    System.cmd("mkdir", [new_path])
    file_hierarchy(left, new_path)
    file_hierarchy(right, new_path)
  end

  @spec rebuild_file_structure(root, charlist()) :: nil
  def rebuild_file_structure(root, path) do
    [root_dir | []] = File.ls!(path)
    System.cmd("mv", [path <> "/#{root_dir}", path <> "/#{root.value}"])
    restructure_directories(root, path <> "/#{root.value}")
  end

  @spec restructure_directories(root, charlist()) :: nil
  def restructure_directories(root, path) do
    case File.ls(path) do
      {:error, _} ->
        System.cmd("mv", [path |> Path.split |> Enum.at(-1), root.value])
      {:ok, [left | []]} ->
        [left_tree |[]] = root.children
        if left != left_tree.value do
          System.cmd("rm", ["-r", "*"])
          file_hierarchy(left_tree, path)
        end
      {:ok, [left | [right]]} ->
        [left_tree | [right_tree]] = root.children
        cond do
          left_tree == left and right_tree == right ->
            nil
          left_tree == right and right_tree == left ->
            nil
          left_tree == left ->
            System.cmd("mv", [right, right_tree.value])
            restructure_directories(right_tree, path <> "/#{right_tree.value}")
          left_tree == right ->
            System.cmd("mv", [left, right_tree.value])
            restructure_directories(right_tree, path <> "/#{right_tree.value}")
          right_tree == left ->
            System.cmd("mv", [right, left_tree.value])
            restructure_directories(left_tree, path <> "/#{left_tree.value}")
          right_tree == right ->
            System.cmd("mv", [left, left_tree.value])
            restructure_directories(left_tree, path <> "/#{left_tree.value}")
          true ->
            System.cmd("rm", ["-r", "*"])
        end

    end
  end

  @spec build(pieces, hash_function | Keyword.t()) :: root
  def build(pieces, hash_function \\ nil)
  def build(pieces, hash_function) when is_function(hash_function) do
    leaves = Enum.map(pieces, fn(piece) ->
      %Node{
        value: hash_function.(piece),
        data: piece,
        children: []
        }
      end)
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
      %Node{
        value: hash_function.(concat),
        children: partition,
      }
    end)
    build_tree(parents, hash_function)
  end

  @spec deserialize(charlist(), root) :: IO
  def deserialize(path, root) do
    content =
      root
      |> reconstruct()
      |> Enum.join()
    File.write(path, content)
  end

  @spec reconstruct(root) :: [charlist()]
  def reconstruct(root), do: _reconstruct([root])

  defp _reconstruct([]), do: []
  defp _reconstruct([%Node{:children => children, :data => nil} | tail]) do
    _reconstruct(children++tail)
  end
  defp _reconstruct([%Node{:data => data} | tail]) do
    [data | _reconstruct(tail)]
  end


  @spec verify(root, root) :: Boolean
  def verify(%Node{:value => value1},
             %Node{:value => value2}), do: value1 == value2

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

  @spec rebuild_file_structure_after_edits(charlist(), hash_function | Keyword.t()) :: t
  def rebuild_file_structure_after_edits(path, hash_function) do
    root = rebuild_tree_after_edits(path, hash_function)
    rebuild_file_structure(root, path)
    root
  end

  @spec rebuild_tree_after_edits(charlist(), hash_function | Keyword.t()) :: t
  def rebuild_tree_after_edits(path, hash_function) do
    path
    |> construct_tree_from_directories
    |> reconstruct
    |> build(hash_function)
  end

  @spec construct_tree_from_directories(charlist()) :: root
  def construct_tree_from_directories(path) do
    is_directory(File.ls(path), path)
  end

  @spec is_directory(%{}, charlist()) :: root
  defp is_directory({:error, _}, path) do
    %Node{
      :value => path |> Path.split |> Enum.at(-1),
      :data => File.read!(path)
    }
  end

  defp is_directory({:ok, dirs}, path) do
    root =
      path
      |> Path.split()
      |> Enum.at(-1)
    children = Enum.map(dirs, fn(sub) ->
      construct_tree_from_directories(path <> "/#{sub}")
    end)
    %Node{:value => root, :children => children}
  end

end
