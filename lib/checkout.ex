defmodule Checkout do
  @moduledoc """
  Module for Cart struct and context. In real application, this module would be splitted in 2 parts: Cart schema and Cart context.
  Also in real app cart could has user assigned (e.g. when buyer using personal loyality card)

  Creating cart isn't required by task, but cart info (such as products and discounts) could be used with minor code changes.


  N.B. discount application isn't commutative/associative operation, so order of discounts in list_of_cart_discounts is important
  E.g. if you have 2 discounts:
    1) if you buy >= 3 strawberries (5$ per item) you get 10% discount for total strawberries price
    2) if you buy for amount >= 10$ you get 2$ discount
  If buying 3 strawberies, and applying 1st then 2nd discounts you will get total price (3 * 5$) * 0.9 - 2$ = 11,5$
  but if you apply 2nd then 1st discounts you will get total price ((3 * 5$) - 2$) * 0.9 = 11,7$
  """

  require Logger

  import Products

  @type t :: %{
          id: String.t(),
          total: Decimal.t(),
          list_products_in_cart: [String.t()],
          list_of_cart_discounts: [fun()]
        }

  defstruct id: "",
            total: Decimal.new("0"),
            list_products_in_cart: [],
            list_of_cart_discounts: [],
            list_of_applied_discounts: []

  @discounts [
    %{
      name: ceo_discount_name(),
      discount_fn: &ceo_discount/3,
      description: "Green tea: buy 1 and get 1 free"
    },
    %{
      name: coo_discount_name(),
      discount_fn: &coo_discount/3,
      description: "Strawberries: buy >=3 and get price 4.50 for strawbery"
    },
    %{
      name: cto_discount_name(),
      discount_fn: &cto_discount/3,
      description: "Coffee: buy >=3 and get 2/3 of the price for all coffee"
    }
  ]

  @doc """
  Calculate total price of products in cart.

  Args: products - product or list of products to be added to cart.
        cart - cart struct, can be %{id: cart_id}, nil or just skipped
        discounts - list of discounts to be applied to cart. If nil, default discounts will be used.
          If list of discounts is passed, it will overwrite existing cart's discount

  Returns: {:ok, total_price} or {:error, reason}

  Examples:
      create cart and return total price with default discounts:
        checkout(["GR1", "SR1", "GR1", "CF1"])

      create cart with id if doesn't exist / reads from ETS if exists and return total price with default discounts:
        checkout(["GR1", "SR1", "GR1", "CF1"],  cart_id)

      calculate price for empty cart
        checkout([], %{id: cart_id})

      create cart and return total price with custom discounts:
        checkout(["GR1", "SR1", "GR1", "CF1"], nil, discount_list)

      create/reads cart and override default discounts and return total price with custom discounts:
        checkout(["GR1", "SR1", "GR1", "CF1"], %{id: cart_id}, discount_list)
  """

  def checkout(products, cart \\ nil, new_discounts \\ nil)

  def checkout(products, nil, new_discounts),
    do: checkout(products, %{id: UUID.uuid4()}, new_discounts)

  def checkout(products, %{id: id} = _cart, new_discounts) when is_list(products) do
    case process_cart(id, products, new_discounts) do
      {:ok, updated_cart} ->
        :ets.insert(:carts, {id, updated_cart})
        {:ok, updated_cart.total}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def checkout(product, cart, new_discounts) when is_binary(product),
    do: checkout([product], cart, new_discounts)

  def checkout(product, cart_id, new_discounts) when is_binary(cart_id),
    do: checkout(product, %{id: cart_id}, new_discounts)

  defp get_cart(cart_id) do
    case :ets.lookup(:carts, cart_id) do
      [{^cart_id, cart}] ->
        {:ok, cart}

      [] ->
        {:error, "cart not found"}
    end
  end

  defp process_cart(cart_id, products, new_discounts) do
    case get_cart(cart_id) do
      {:ok, existing_cart} ->
        update_cart(existing_cart, products, new_discounts)

      {:error, _message} ->
        create_cart(cart_id, products, new_discounts)
    end
  end

  defp update_cart(cart, products, discounts) do
    updated_products = cart.list_products_in_cart ++ products

    updated_discounts =
      case discounts do
        nil -> cart.list_of_cart_discounts
        _ -> discounts
      end

    case calculate_total(updated_products, updated_discounts) do
      {:ok, {total, applied_discounts}} ->
        {
          :ok,
          %{
            cart
            | list_products_in_cart: updated_products,
              list_of_cart_discounts: updated_discounts,
              list_of_applied_discounts: applied_discounts,
              total: total
          }
        }

      {:error, message} ->
        {:error, message}
    end
  end

  defp create_cart(cart_id, products, nil), do: create_cart(cart_id, products, @discounts)

  defp create_cart(cart_id, products, discounts) do
    case calculate_total(products, discounts) do
      {:ok, {total, applied_discounts}} ->
        {
          :ok,
          %{
            id: cart_id,
            list_products_in_cart: products,
            list_of_cart_discounts: discounts,
            list_of_applied_discounts: applied_discounts,
            total: total
          }
        }

      {:error, message} ->
        {:error, message}
    end
  end

  defp calculate_total(products, discounts) do
    cart_base_price = cart_base_price(products)

    case cart_base_price do
      {:error, product} ->
        Logger.error("checkout error creating cart - product not found: #{inspect(product)}")
        {:error, "product not found"}

      {:ok, base_price} ->
        {total, applied_discounts} =
          Enum.reduce(discounts, {base_price, []}, fn %{
                                                        name: discount_name,
                                                        discount_fn: discount_fn
                                                      } = _discount,
                                                      {total, applied_discounts} = _acc ->
            {total, applied} = discount_fn.(total, products, applied_discounts)

            applied_discounts =
              if applied, do: [discount_name | applied_discounts], else: applied_discounts

            {total, applied_discounts}
          end)

        {:ok, {Decimal.round(total, 2), applied_discounts}}
    end
  end

  defp cart_base_price(products) do
    result =
      Enum.reduce(products, Decimal.new("0"), fn product, acc ->
        case Map.get(all(), product) do
          nil -> {:error, product}
          price -> Decimal.add(price, acc)
        end
      end)

    case result do
      {:error, _product} = error -> error
      price -> {:ok, price}
    end
  end
end
