defmodule Products do
  @moduledoc """
  Module for products and discount functions.
  """
  # Just for testing purpose. Of course should be stored in db.
  @products %{
    "GR1" => Decimal.new("3.11"),
    "SR1" => Decimal.new("5.00"),
    "CF1" => Decimal.new("11.23")
  }

  def get_product_price(code), do: @products[code]

  def all, do: @products

  def ceo_discount_name, do: "CEO"

  def coo_discount_name, do: "COO"

  def cto_discount_name, do: "CTO"

  # CEO discount: Buy-one-get-one-free for green tea
  def ceo_discount(total, products, applied_discounts) do
    with true <- applicable?(ceo_discount_name(), applied_discounts),
         green_tea_quantity = Enum.count(products, fn product -> product == "GR1" end),
         true <- green_tea_quantity >= 2 do
      discount = Decimal.mult(get_product_price("GR1"), div(green_tea_quantity, 2))
      final_price = Decimal.sub(total, discount)
      {final_price, true}
    else
      _ ->
        {total, false}
    end
  end

  # COO discount: Bulk discount for strawberries
  def coo_discount(total, products, applied_discounts) do
    strawberry_quantity = Enum.count(products, fn product -> product == "SR1" end)

    with true <- applicable?(coo_discount_name(), applied_discounts),
         true <- strawberry_quantity >= 3 do
      discount =
        "SR1"
        |> get_product_price()
        |> Decimal.sub(Decimal.new("4.50"))
        |> Decimal.mult(strawberry_quantity)

      final_price = Decimal.sub(total, discount)

      {final_price, true}
    else
      _ ->
        {total, false}
    end
  end

  # CTO discount: Coffee addict discount
  def cto_discount(total, products, applied_discounts) do
    coffee_quantity = Enum.count(products, fn product -> product == "CF1" end)

    with true <- applicable?(cto_discount_name(), applied_discounts),
         true <- coffee_quantity >= 3 do
      discount =
        "CF1"
        |> get_product_price()
        |> Decimal.mult(coffee_quantity)
        # discoount ~33%
        |> Decimal.div(3)

      final_price = Decimal.sub(total, discount)
      {final_price, true}
    else
      _ ->
        {total, false}
    end
  end

  defp applicable?(discount_name, applied_discounts) do
    discount_name not in applied_discounts
  end
end
