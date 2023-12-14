class AddSourceToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :source, :string
  end
end
