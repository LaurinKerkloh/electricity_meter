require "net/http"
class TriggerPoint < ApplicationRecord
  enum :direction, {up: "up", down: "down"}, validate: true

  default_scope { order(:position) }

  before_create :set_position
  before_update :adjust_positions_on_update
  before_destroy :decrement_higher_positions

  validates :power, presence: true
  validates :scene, presence: true

  def trigger
    Rails.logger.info("Triggering Scene: #{scene}")
    response = Net::HTTP.get(URI("http://192.168.0.62/control?scene=#{scene}"))
    Rails.logger.info(response)
  end

  private

  def set_position
    self.position = (TriggerPoint.maximum(:position) || -1) + 1
  end

  def adjust_positions_on_update
    if position_was < position
      # Moving downwards, shift items up between the old and new position
      TriggerPoint.where(position: (position_was + 1)..position).update_all("position = position - 1")
    elsif position_was > position
      # Moving upwards, shift items down between the new and old position
      TriggerPoint.where(position: position...position_was).update_all("position = position + 1")
    end
  end

  def decrement_higher_positions
    TriggerPoint.where("position > ?", position).update_all("position = position - 1")
  end
end
