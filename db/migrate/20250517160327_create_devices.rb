class CreateDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :devices do |t|
      t.boolean :on, null: false, default: false
      t.string :on_scene, null: false
      t.string :off_scene, null: false

      t.boolean :disabled, null: false, default: false

      t.integer :priority, null: false

      t.integer :marker_position, null: false

      t.string :name, null: false

      t.timestamps
    end
  end
end
