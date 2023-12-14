class AddTrustTypeToSources < ActiveRecord::Migration[5.2]
  def change
    add_column :sources, :trust_type, :string
  end
end
