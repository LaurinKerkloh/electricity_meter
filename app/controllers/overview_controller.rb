class OverviewController < ApplicationController
  def show
    @house = ElectricityMeterReading.house.last
    @solar = ElectricityMeterReading.solar.last
  end
end
