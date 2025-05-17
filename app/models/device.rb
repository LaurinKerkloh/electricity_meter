class Device < ApplicationRecord
  before_create :set_priority
  before_update :adjust_priorities_on_update
  before_destroy :decrement_higher_priorities


  validates :name, presence: true
  validates :on_scene, presence: true
  validates :off_scene, presence: true
  validates :marker_position, presence: true, numericality: {greater_than_or_equal_to: 0}

  def self.update_states
    marker = LightManager.read_marker
    self.class.each do |device|
      device.update(on: marker[device.marker_position])
    end
  end

  def switch_on
    LightManager.trigger_scene(on_scene)
  end

  def switch_off
    LightManager.trigger_scene(off_scene)
  end

  private

  def set_priority
    self.priority = (self.class.maximum(:priority) || -1) + 1
  end

  def adjust_priorities_on_update
    if priority_was < priority
      # Moving downwards, shift items up between the old and new priority
      self.class.where(priority: (priority_was + 1)..priority).update_all("priority = priority - 1")
    elsif priority_was > priority
      # Moving upwards, shift items down between the new and old priority
      self.class.where(priority: priority...priority_was).update_all("priority = priority + 1")
    end
  end

  def decrement_higher_priorities
    self.class.where("priority > ?", priority).update_all("priority = priority - 1")
  end

end
