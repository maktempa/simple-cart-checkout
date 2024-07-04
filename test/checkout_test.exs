defmodule CheckoutTest do
  use ExUnit.Case

  import Checkout

  setup tags do
    case tags[:products] do
      nil ->
        {:ok, products: []}

      products when is_binary(products) ->
        products = String.split(products, " ")
        id = UUID.uuid4()
        total = checkout(products, id)
        {:ok, id: id, total: total}
    end
  end

  describe "checkout new carts" do
    test "returns 0.00 price for an empty cart" do
      checkout = checkout([])
      assert checkout == {:ok, Decimal.new("0.00")}
    end

    @tag products: "GR1"
    test "calculates total price for a single product list", %{total: total} do
      assert total == {:ok, Decimal.new("3.11")}
    end

    test "calculates total price for a single product string" do
      checkout = checkout("GR1")
      assert checkout == {:ok, Decimal.new("3.11")}
    end

    @tag products: "GR1 SR1 CF1"
    test "calculates total price for multiple products without discounts", %{total: total} do
      assert total == {:ok, Decimal.new("19.34")}
    end

    @tag products: "GR1 GR1 GR1"
    test "applies CEO discount: buy-one-get-one-free for green tea", %{total: total} do
      assert total == {:ok, Decimal.new("6.22")}
    end

    @tag products: "SR1 SR1 SR1"
    test "applies COO discount: bulk discount for strawberries", %{total: total} do
      assert total == {:ok, Decimal.new("13.50")}
    end

    @tag products: "CF1 CF1 CF1"
    test "applies CTO discount: coffee addict discount", %{total: total} do
      assert total == {:ok, Decimal.new("22.46")}
    end

    @tag products: "GR1 GR1 SR1 SR1 CF1 CF1 CF1"
    test "applies multiple discounts", %{total: total} do
      assert total == {:ok, Decimal.new("35.57")}
    end

    @tag products: "XYZ"
    test "handles invalid product code", %{total: total} do
      assert total == {:error, "product not found"}
    end

    # test from test data in task description
    @tag products: "GR1 SR1 GR1 GR1 CF1"
    test "test data 1 - 3 green tea", %{total: total} do
      assert total == {:ok, Decimal.new("22.45")}
    end

    # test from test data in task description
    @tag products: "GR1 GR1"
    test "test data 2 - 2 green tea", %{total: total} do
      assert total == {:ok, Decimal.new("3.11")}
    end

    # test from test data in task description
    @tag products: "SR1 SR1 GR1 SR1"
    test "test data 3 - 3 strawberries", %{total: total} do
      assert total == {:ok, Decimal.new("16.61")}
    end

    # test from test data in task description
    @tag products: "GR1 CF1 SR1 CF1 CF1"
    test "test data 4 - 3 coffee", %{total: total} do
      assert total == {:ok, Decimal.new("30.57")}
    end

    # (2 GR * 3.11$ - 1 GR * 3.11$) + (3 SR * 4.50$) = 16,61$
    @tag products: "GR1 GR1 SR1 SR1 SR1"
    test "applying 2 discounts: green tee + strawberry", %{total: total} do
      assert total == {:ok, Decimal.new("16.61")}
    end

    @tag products: "SR1 GR1 SR1 SR1 GR1"
    test "applying 2 discounts: green tee + strawberry, version 2", %{total: total} do
      assert total == {:ok, Decimal.new("16.61")}
    end

    # ((3 GR1 * 3.11$) - (div (3 GR1 2) * 3.11)) + (5 SR1 * 4.50$) + ((4 CF1 * 11.23$) * 2/3) = 58,67$
    @tag products: "GR1 GR1 GR1 SR1 SR1 SR1 SR1 SR1 CF1 CF1 CF1 CF1"
    test "applying 3 discounts", %{total: total} do
      assert total == {:ok, Decimal.new("58.67")}
    end

    @tag products: "CF1 GR1 GR1 GR1 SR1 SR1 SR1 SR1 CF1 CF1 CF1 SR1"
    test "applying 3 discounts version 2", %{total: total} do
      assert total == {:ok, Decimal.new("58.67")}
    end
  end

  describe "checkout existing carts" do
    # 1st checkout: (2 GR * 3.11$ - 1 GR * 3.11$) + (1 SR * 5.00$) + (1 CF * 11.23$) = 19.34$
    # 2nd checkout: (2 GR * 3.11$ - 1 GR * 3.11$) + (3 SR * 4.50$) + (3 CF * 11.23$ * 2/3) = 39.07$
    @tag products: "GR1 SR1 GR1 CF1"
    test "calculates total price for cart: GR1, SR1, GR1, CF1, then adds 2 SR1 and 2 CF1", %{
      id: id,
      total: total
    } do
      assert total == {:ok, Decimal.new("19.34")}

      checkout = checkout(["SR1", "SR1", "CF1", "CF1"], %{id: id})

      assert checkout == {:ok, Decimal.new("39.07")}
    end

    # 1st checkout: (2 GR * 3.11$ - 1 GR * 3.11$) + (1 SR * 5.00$) + (1 CF * 11.23$) = 19.34$
    # 2nd checkout: (2 GR * 3.11$) + (3 SR * 5.00$) + (3 CF * 11.23$) = 54.91$
    @tag products: "GR1 SR1 GR1 CF1"
    test "calculates total price for cart: GR1, SR1, GR1, CF1, then adds 2 SR1 and 2 CF1 and recalculate cart w/o discounts applied",
         %{id: id, total: total} do
      assert total == {:ok, Decimal.new("19.34")}

      checkout = checkout(["SR1", "SR1", "CF1", "CF1"], %{id: id}, [])

      assert checkout == {:ok, Decimal.new("54.91")}
    end
  end
end
