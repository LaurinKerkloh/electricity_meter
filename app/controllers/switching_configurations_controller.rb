class SwitchingConfigurationsController < ApplicationController
  before_action :set_switching_configuration
  def edit
  end

  def update
    @switching_configuration.update(configuraition_params)
    redirect_to Device
  end

  private

  def set_switching_configuration
    @switching_configuration = SwitchingConfiguration.load
  end

  def configuraition_params
    on_below = params.dig(:switching_configuration, :on_below)
    params[:switching_configuration][:on_below] = -on_below if on_below.present?
    params.expect(switching_configuration: [:on_below, :off_above, :disable_switching])
  end
end
