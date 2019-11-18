defmodule CoreTest do
  use ExUnit.Case
  alias MerkleTree.{Core, Node, Crypto}

  test "synchronize two leaves" do
    root1 = %Node{:value => "123", :children => [] }
    root2 = %Node{:value => "234", :children => []}

    assert Core.synchronize(root1, root2) == root2
  end

  test "synchronize two full trees" do
    root1 = %Node{
      :value => "1",
      :children => [
        %Node{
          :value => "2",
          :children => [
            %Node{
              :value => "3",
              :children => []
            },%Node{
              :value => "4",
              :children => []
            }
          ]
        },%Node{
          :value => "5",
          :children => [
            %Node{
              :value => "6",
              :children => []
            },%Node{
              :value => "7",
              :children => []
            }
          ]
        }
      ]
    }
    root2 = %Node{
      :value => "10",
      :children => [
        %Node{
          :value => "2",
          :children => [
            %Node{
              :value => "3",
              :children => []
            },%Node{
              :value => "4",
              :children => []
            }
          ]
        },%Node{
          :value => "15",
          :children => [
            %Node{
              :value => "16",
              :children => []
            },%Node{
              :value => "17",
              :children => []
            }
          ]
        }
      ]
    }
    assert Core.synchronize(root1, root2) ==
      %Node{
        :value => "15",
        :children => [
          %Node{
            :value => "16",
            :children => []
          },%Node{
            :value => "17",
            :children => []
          }
        ]
      }
  end

  test "serialize and deserialize with the same file" do
    pid = MerkleTree.start
    path = "../../assets/test_serialization/file1/file1.png"
    root = MerkleTree.serialize(pid, path)
    write_path = "../../assets/test_serialization/file1/new_img.png"
    MerkleTree.deserialize(pid,write_path,root)
    assert System.cmd("cmp", ["--silent", path, write_path, "||", "echo", "different"]) != "different"
  end

  test "synchronize two minimal files" do
    pid = MerkleTree.start()
    path_file1 =
      "../assets/test_sync/file1/text_file1.txt"
      |> Path.expand(__DIR__)
    path_file2 =
      "../assets/test_sync/file2/text_file2.txt"
      |> Path.expand(__DIR__)

    content = "Hello, I love ACID Transactions and Fault Tolerant Cloud-based Distributed System."
    File.write(path_file1, content)
    File.write(path_file2, content)

    root1 = MerkleTree.serialize(pid, path_file1)
    root2 = MerkleTree.serialize(pid, path_file2)

    tmp =
      path_file1
      |> Path.split
      |> Enum.drop(-1)
      |> Path.join

    prefix = tmp <> "/_text_file1.txt"

    IO.inspect(prefix <> "/#{root1.value}")
    new_content = "Hello friends, I love P2P Cloud-based Decentralized System."
    File.write(prefix <> "/#{root1.value}", new_content)

    Core.rebuild_file_structure_after_edits(prefix, &Crypto.sha256/1)
  end

end
