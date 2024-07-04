# Cart

Simple function to checkout products with applied discount rules.
Stores cart information in ETS so products can be added to cart at any point after creation.


  Function: checkout/3
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

## Installation
```bash
mix deps.get
```
### To run project with iex.
```bash
iex -S mix
```
### To run tests
```bash
mix test
```