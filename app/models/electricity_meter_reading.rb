class ElectricityMeterReading < ApplicationRecord
  SWITCH_OFF_ABOVE = 0
  SWITCH_ON_BELOW = -400

  enum :meter, {house: "house", solar: "solar"}, validate: true
  broadcasts_refreshes

  after_commit :switch_device, on: :create

  private

  def switch_device
    return unless house?

    return if current_power.between?(SWITCH_ON_BELOW, SWITCH_OFF_ABOVE)

    Device.update_states

    if current_power < SWITCH_ON_BELOW
      Device.where(on: false).order(priority: :asc).first&.switch_on
    end

    if current_power > SWITCH_OFF_ABOVE
      Device.where(on: true).order(priority: :desc).first&.switch_off
    end
  end
end
