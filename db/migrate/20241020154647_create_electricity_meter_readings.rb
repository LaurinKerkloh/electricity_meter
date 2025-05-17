class CreateElectricityMeterReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :electricity_meter_readings do |t|
      t.datetime :time, null: false
      t.decimal :reading, precision: 10, scale: 4
      t.integer :current_power
      t.string :meter, null: false

      t.timestamps

      t.index [:time, :meter], unique: true
    end
  end
end
