class CreateUsers < ActiveRecord::Migration[5.1]
  def self.up
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :password_hash
      t.string :token
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
