class CreateTriggerPoints < ActiveRecord::Migration[8.1]
  def change
    create_table :trigger_points do |t|
      t.string :direction, null: false
      t.integer :power, null: false
      t.string :scene, null: false
      t.integer :position, null: false
      t.string :name

      t.timestamps
    end
  end
end
