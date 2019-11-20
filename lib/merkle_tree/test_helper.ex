defmodule MerkleTree.TestHelper do
  def write_to_the_start_of_file(path,data) do
    path
    |> File.ls
    |> write_to(path, data)
  end

  defp write_to({:error, _}, path, data) do
    File.write(path, data)
  end

  defp write_to({:ok, [left| _]}, path, data) do
    write_to_the_start_of_file(path <> "/#{left}", data)
  end
end
