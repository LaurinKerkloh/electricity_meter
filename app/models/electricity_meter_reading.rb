class ElectricityMeterReading < ApplicationRecord
  OFF_ABOVE = 0 
  ON_BELOW = -400
  enum :meter, {house: "house", solar: "solar"}, validate: true
  broadcasts_refreshes

  after_commit :switch_device, on: :create

  private

  def switch_device
    return unless house?

    return if power <= OFF_ABOVE && power >= ON_BELOW

    Device.update_states

    if power < ON_BELOW
      Devices.where(on: false).order(priority: :asc).first&.switch_on
    end

    if power > OFF_ABOVE
      Devices.where(on: true).order(priority: :desc).first&.switch_off
    end
  end

end
