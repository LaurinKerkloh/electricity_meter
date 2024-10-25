class TriggerPointsController < ApplicationController
  def index
    @trigger_points = TriggerPoint.all
  end

  def new
    @trigger_point = TriggerPoint.new
  end

  def create
    @trigger_point = TriggerPoint.new(trigger_point_params)
    if @trigger_point.save
      redirect_to trigger_points_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @trigger_point = TriggerPoint.find(params[:id])
  end

  def update
    @trigger_point = TriggerPoint.find(params[:id])
    if @trigger_point.update(trigger_point_params)
      redirect_to trigger_points_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @trigger_point = TriggerPoint.find(params[:id])
    @trigger_point.destroy

    redirect_to trigger_points_path
  end

  private

  def trigger_point_params
    params.require(:trigger_point).permit(:direction, :power, :scene, :position, :name)
  end
end
