class DevicesController < ApplicationController
  def index
    @devices = Device.all.order(:priority)
    @switching_configuration = SwitchingConfiguration.load
  end

  def new
    @device = Device.new
  end

  def create
    @device = Device.new(device_params)
    if @device.save
      redirect_to devices_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @device = Device.find(params[:id])
  end

  def update
    @device = Device.find(params[:id])
    if @device.update(device_params)
      redirect_to devices_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @device = Device.find(params[:id])
    @device.destroy

    redirect_to devices_path
  end

  private

  def device_params
    params.require(:device).permit(:on_scene, :off_scene, :marker_position, :name, :priority)
  end
end
