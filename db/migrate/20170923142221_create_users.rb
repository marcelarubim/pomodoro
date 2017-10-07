class CreateUsers < ActiveRecord::Migration[5.1]
  def self.up
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :password_hash
      t.integer :role
      t.boolean :blocked
      t.boolean :email_verified
      t.string :last_ip
      t.timestamp :last_login
      t.integer :logins_count
      t.string :timezone
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
