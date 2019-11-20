defmodule MerkleTree.Utilities do
  def get_prefix(path) do
    get_enclosing_folder(path) <> "/_#{get_file_name(path)}"
  end

  def get_file_name(path) do
    path
    |> Path.split()
    |> Enum.at(-1)
  end

  def path_to_file(path, file) do
    path <> "/#{file}"
  end

  def get_enclosing_folder(path) do
    path
    |> Path.split
    |> Enum.drop(-1)
    |> Path.join
  end
end
