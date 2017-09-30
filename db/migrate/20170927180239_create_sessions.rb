class CreateSessions < ActiveRecord::Migration[5.1]
  def self.up
    create_table :sessions do |t|
      t.string :title
      t.time :start
      t.time :final
      t.references :user, foreign_key: true
      t.timestamps
    end
  end

  def self.down
    drop_table :sessions
  end
end
