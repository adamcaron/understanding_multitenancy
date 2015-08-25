class Stores::ItemsController < Stores::StoresController
  def index
    @items = current_store.items
  end

  def show
    @item = current_store.items.find_by(id: params[:id])

    redirect_to store_items_path(store: current_store.url), notice: "Item not found" unless @item
  end
end
