class SwitchingConfiguration < ApplicationRecord
  before_create :check_for_existing
  before_destroy :check_for_existing

  def self.load
    config = SwitchingConfiguration.first

    if config.nil?
      config = SwitchingConfiguration.create
    end

    config
  end

  private

  def check_for_existing
    raise ActiveRecord::RecordInvalid if SwitchingConfiguration.count >= 1
  end
end
