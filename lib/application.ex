# defmodule Cart.Application do
#   use Application

#     # :ets.new(:carts, [:named_table, :public, read_concurrency: true])

#   def start(_type, _args) do
#   # children = [
#   #     {TodoApp.Repo, []}
#   # ]
#   opts = [strategy: :one_for_one, name: CartSupervisor]
#   # Supervisor.start_link(children, opts)
#   Cart.Supervisor.start_link(opts)
#   end
# end

defmodule Cart.Application do
  use Application

  def start(_type, _args) do
    :ets.new(:carts, [:named_table, :public, read_concurrency: true])
    {:ok, self()}
  end
end
