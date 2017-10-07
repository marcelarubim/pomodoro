class CreateTokens < ActiveRecord::Migration[5.1]
  def self.up
    create_table :tokens do |t|
      t.string :token
      t.string :aud
      t.integer :grant_type, default: 0
      t.string :blacklist, default: false
      t.references :user, foreign_key: true
      t.timestamps
    end
  end

  def self.down
    drop_table :tokens
  end
end
