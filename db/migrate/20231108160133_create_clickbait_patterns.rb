class CreateClickbaitPatterns < ActiveRecord::Migration[5.2]
  def change
    create_table :clickbait_patterns do |t|
      t.string :pattern

      t.timestamps
    end
  end
end
