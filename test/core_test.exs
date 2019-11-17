defmodule CoreTest do
  use ExUnit.Case
  alias MerkleTree.{Core, Node}

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
end
