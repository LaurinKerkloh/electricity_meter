class ElectricityMeterReading < ApplicationRecord
  enum :meter, {house: "house", solar: "solar"}, validate: true
  broadcasts_refreshes

  after_commit :switch_device, on: :create

  private

  def switch_device
    return unless house?

    Device.update_states

    @config = SwitchingConfiguration.load

    return if @config.disable_switching

    return if current_power.between?(@config.on_below, @switch.off_above)

    if current_power < @config.on_below
      Device.where(on: false).order(priority: :asc).first&.switch_on
    end

    if current_power > @config.off_above
      Device.where(on: true).order(priority: :desc).first&.switch_off
    end
  end
end
