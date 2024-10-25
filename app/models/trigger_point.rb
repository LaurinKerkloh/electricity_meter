require "net/http"
class TriggerPoint < ApplicationRecord
  enum :direction, {up: "up", down: "down"}, validate: true

  default_scope { order(:position) }

  before_validation :set_position, on: :create
  after_update :switch_position

  validates :power, presence: true
  validates :scene, presence: true
  validates :position, presence: true, numericality: {greater_than_or_equal_to: 0}

  def trigger
    Rails.logger.info("Triggering Scene: #{scene}")
    response = Net::HTTP.get(URI("http://192.168.0.62/control?scene=#{scene}"))
    Rails.logger.info(response)
  end

  private

  def set_position
    last = TriggerPoint.reorder(:position).last
    self.position = if last.present?
      last.position + 1
    else
      0
    end
  end

  def switch_position
    TriggerPoint.find_by(position: position).update_column(:position, position_was)
  end
end
