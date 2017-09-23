class CreateRecords < ActiveRecord::Migration[5.1]
  def self.up
    create_table :records do |t|
      t.string :title
      t.datetime :start
      t.datetime :end

      t.timestamps
    end
  end

  def self.down
    drop_table :records
  end
end
