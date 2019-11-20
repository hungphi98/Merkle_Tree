defmodule CoreTest do
  use ExUnit.Case
  alias MerkleTree.{Core, Node, Crypto, Sync, FileHierarchy, Serializer, TestHelper, Utilities}

  # test "synchronize two leaves" do
  #   root1 = %Node{:value => "123", :children => [] }
  #   root2 = %Node{:value => "234", :children => []}
  #
  #   assert Sync.synchronize(root1, root2) == root2
  # end
  #
  # test "synchronize two full trees" do
  #   root1 = %Node{
  #     :value => "1",
  #     :children => [
  #       %Node{
  #         :value => "2",
  #         :children => [
  #           %Node{
  #             :value => "3",
  #             :data => "12333",
  #             :children => [],
  #           },%Node{
  #             :value => "4",
  #             :data => "12333",
  #             :children => [],
  #           }
  #         ]
  #       },%Node{
  #         :value => "5",
  #         :children => [
  #           %Node{
  #             :value => "6",
  #             :data => "123",
  #             :children => [],
  #           },%Node{
  #             :value => "7",
  #             :data => "1234",
  #             :children => [],
  #           }
  #         ]
  #       }
  #     ]
  #   }
  #   root2 = %Node{
  #     :value => "10",
  #     :children => [
  #       %Node{
  #         :value => "2",
  #         :children => [
  #           %Node{
  #             :value => "3",
  #             :children => []
  #           },%Node{
  #             :value => "4",
  #             :children => []
  #           }
  #         ]
  #       },%Node{
  #         :value => "15",
  #         :children => [
  #           %Node{
  #             :value => "16",
  #             :children => []
  #           },%Node{
  #             :value => "17",
  #             :children => []
  #           }
  #         ]
  #       }
  #     ]
  #   }
  #   assert Sync.synchronize(root1, root2) ==
  #     %Node{
  #       :value => "15",
  #       :children => [
  #         %Node{
  #           :value => "16",
  #           :children => []
  #         },%Node{
  #           :value => "17",
  #           :children => []
  #         }
  #       ]
  #     }
  # end
  #
  # test "serialize and deserialize with the same file" do
  #   pid = MerkleTree.start
  #   path =
  #     "../assets/test_serialization/file1/file1.png"
  #     |> Path.expand(__DIR__)
  #
  #   write_path =
  #     Utilities.get_enclosing_folder(path)
  #     |> Utilities.path_to_file("new_#{Utilities.get_file_name(path)}")
  #
  #   root = MerkleTree.serialize(pid, path)
  #   MerkleTree.deserialize(pid,path)
  #   assert System.cmd("cmp", ["--silent", path, write_path, "||", "echo", "different"]) != "different"
  # end
  #
  # test "synchronize two minimal files" do
  #   pid = MerkleTree.start()
  #   path_file =
  #     "../assets/test_sync/file1/text_file1.txt"
  #     |> Path.expand(__DIR__)
  #
  #   content = "Hello, I love ACID Transactions and Fault Tolerant Cloud-based Distributed System."
  #   File.write(path_file, content)
  #
  #   root1 = MerkleTree.serialize(pid, path_file)
  #
  #   prefix = Utilities.get_prefix(path_file)
  #
  #   new_content = "Hello friends, I love P2P Cloud-based Decentralized System."
  #   TestHelper.write_to_the_start_of_file(prefix, new_content)
  #
  #   root = FileHierarchy.rebuild_file_structure_after_edits(prefix, &Crypto.sha256/1)
  #   MerkleTree.deserialize(pid, path_file)
  # end

  test "test reconstruct file hierarchy after editting files" do
    pid = MerkleTree.start
    file_path_1 =
      "../assets/file1/file1.txt"
      |> Path.expand(__DIR__)
    MerkleTree.serialize(pid, file_path_1)

    prefix = Utilities.get_prefix(file_path_1)
    TestHelper.write_to_the_start_of_file(prefix, "Some made up stuff")

    FileHierarchy.rebuild_file_structure_after_edits(prefix, &Crypto.sha256/1)

    MerkleTree.deserialize(pid, file_path_1)
  end

  test "test create new file" do

  end

  test "merge file" do

  end

end
