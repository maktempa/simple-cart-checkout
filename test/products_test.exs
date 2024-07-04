defmodule ProductsTest do
  use ExUnit.Case

  import Products

  describe "Products" do
    test "CEO discount: buy-one-get-one-free for green tea" do
      products = ["GR1", "GR1", "GR1"]
      applied_discounts = []
      total = Decimal.mult(3, get_product_price("GR1"))

      assert ceo_discount(total, products, applied_discounts) == {Decimal.new("6.22"), true}
    end

    test "COO discount: bulk discount for strawberries" do
      products = ["SR1", "SR1", "SR1"]
      applied_discounts = []
      total = Decimal.mult(3, get_product_price("SR1"))

      assert coo_discount(total, products, applied_discounts) == {Decimal.new("13.50"), true}
    end

    test "CTO discount: coffee addict discount" do
      products = ["CF1", "CF1", "CF1"]
      applied_discounts = []
      total = Decimal.mult(3, get_product_price("CF1"))

      assert cto_discount(total, products, applied_discounts) == {Decimal.new("22.46"), true}
    end
  end
end
