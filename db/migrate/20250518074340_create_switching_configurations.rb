class CreateSwitchingConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :switching_configurations do |t|
      t.integer :on_below, default: -400, null: false
      t.integer :off_above, default: 0, null: false

      t.boolean :disable_switching, default: false, null: false

      t.timestamps
    end
  end
end
