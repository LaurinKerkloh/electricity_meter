class ElectricityMeterReading < ApplicationRecord
  enum :meter, {house: "house", solar: "solar"}, validate: true

  after_commit -> { broadcast_refresh_to(:overview) }
end
