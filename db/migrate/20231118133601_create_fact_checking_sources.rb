class CreateFactCheckingSources < ActiveRecord::Migration[5.2]
  def change
    create_table :fact_checking_sources do |t|
      t.string :name
      t.string :url
      t.string :trust_type

      t.timestamps
    end
  end
end
