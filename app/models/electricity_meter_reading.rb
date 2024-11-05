class ElectricityMeterReading < ApplicationRecord
  enum :meter, {house: "house", solar: "solar"}, validate: true
  broadcasts_refreshes

  after_commit :toggle_switch, on: :create

  private

  def toggle_switch
    return unless house?

    previous_reading = ElectricityMeterReading.house.last(2).first
    trigger_points_to_be_triggerd = if current_power > previous_reading.current_power
      TriggerPoint.up.where(power: previous_reading.current_power..current_power)
    elsif current_power < previous_reading.current_power
      TriggerPoint.down.where(power: current_power..previous_reading.current_power)
    else
      []
    end

    trigger_points_to_be_triggerd.each do |trigger_point|
      trigger_point.trigger
    end
  end
end
