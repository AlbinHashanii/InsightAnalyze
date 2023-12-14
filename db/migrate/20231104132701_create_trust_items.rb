class CreateTrustItems < ActiveRecord::Migration[5.2]
  def change
    create_table :trust_items do |t|
      t.string :title
      t.string :text
      t.string :author
      t.string :url
      t.string :classification
      t.datetime :pub_date
      t.integer :user_id
      t.string :type

      t.timestamps
    end
  end
end
