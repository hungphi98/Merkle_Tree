defmodule MerkleTree.FileHierarchy do
  alias MerkleTree.{Node, Crypto, Core, Serializer, Utilities}

  @type pieces :: [String.t(), ...]
  @type hash_function :: (String.t() -> String.t())
  @type root :: Node.t()
  @type t :: %Core{
    pieces: pieces,
    root: root,
    hash_function: hash_function
  }

  @spec build_directories(root, charlist()) :: nil
  def build_directories(root, prefix) do
    case File.ls(prefix) do
      {:error, _} ->
        nil
      {:ok, []} ->
        file_hierarchy(root, prefix)
      {:ok, [root_dir]} ->
        if root_dir != root.value do
          rebuild_file_structure(root, prefix)
        else
          IO.puts("#{root_dir} exists")
        end
    end
  end

  @spec file_hierarchy(root, charlist()) :: nil
  def file_hierarchy(root \\ nil, path)
  def file_hierarchy(%Node{:children => [], :data => data, :value => filename}, path) do
    File.write(Utilities.path_to_file(path, filename), data)
  end
  def file_hierarchy(%Node{:children => [left| []], :value => value}, path) do
    new_path = Utilities.path_to_file(path, value)
    System.cmd("mkdir", [new_path])
    file_hierarchy(left, new_path)
  end
  def file_hierarchy(%Node{:children => [left | [right]], :value => value}, path) do
    new_path = Utilities.path_to_file(path, value)
    System.cmd("mkdir", [new_path])
    file_hierarchy(left, new_path)
    file_hierarchy(right, new_path)
  end

  @spec rebuild_file_structure(root, charlist()) :: nil
  def rebuild_file_structure(root, path) do
    root_dir = path |> File.ls! |> Enum.at(-1)
    System.cmd("mv", [Utilities.path_to_file(path, root_dir), Utilities.path_to_file(path, root.value)])
    restructure_directories(root, Utilities.path_to_file(path, root_dir))
  end

  @spec restructure_directories(root, charlist()) :: nil
  def restructure_directories(root, path) do
    case File.ls(path) do
      {:error, _} ->
        System.cmd("mv", [path |> Path.split |> Enum.at(-1), root.value])
      {:ok, [left | []]} ->
        [left_tree |[]] = root.children
        if left != left_tree.value do
          System.cmd("rm", ["-r", Utilities.path_to_file(path, "*")])
          file_hierarchy(left_tree, path)
        end
      {:ok, [left | [right]]} ->
        [left_tree | [right_tree]] = root.children
        cond do
          left_tree.value == left and right_tree.value == right ->
            nil
          left_tree.value == right and right_tree.value == left ->
            nil
          left_tree.value == left ->
            System.cmd("mv", [Utilities.path_to_file(path, right), Utilities.path_to_file(path, right_tree.value)])
            restructure_directories(right_tree, Utilities.path_to_file(path, right_tree.value))
          left_tree.value == right ->
            System.cmd("mv", [Utilities.path_to_file(path, left), Utilities.path_to_file(path, right_tree.value)])
            restructure_directories(right_tree, Utilities.path_to_file(path, right_tree.value))
          right_tree.value == left ->
            System.cmd("mv", [Utilities.path_to_file(path, right), Utilities.path_to_file(path, left_tree.value)])
            restructure_directories(left_tree, Utilities.path_to_file(path, left_tree.value))
          right_tree.value == right ->
            System.cmd("mv", [Utilities.path_to_file(path, left), Utilities.path_to_file(path, left_tree.value)])
            restructure_directories(left_tree, Utilities.path_to_file(path, left_tree.value))
          true ->
            System.cmd("rm", ["-r", "*"])
            file_hierarchy(root, path)
        end

    end
  end

  @spec rebuild_file_structure_after_edits(charlist(), hash_function | Keyword.t()) :: t
  def rebuild_file_structure_after_edits(path, hash_function) do
    root = rebuild_merkle_tree(path, hash_function)
    rebuild_file_structure(root, path)
    root
  end

  @spec rebuild_merkle_tree(charlist(), hash_function | Keyword.t()) :: t
  defp rebuild_merkle_tree(path, hash_function) do
    path
    |> construct_tree_from_directories
    |> Serializer.reconstruct
    |> Serializer.build(hash_function)
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

  def is_serialized(path, hash_function) do
    case File.ls(path) do
      {:error, _} ->
        false
      {:ok, [root_dir]} ->
        root = rebuild_merkle_tree(path, hash_function)
        if root.value == root_dir do
          true
        else
          System.cmd("rm", ["-r", path])
          false
        end
    end
  end
end
