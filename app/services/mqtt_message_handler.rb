class MqttMessageHandler
  def initialize(topic, message)
    @topic = topic
    @message = message
  end

  def handle
    Rails.logger.info("Handling message from MQTT: #{@message.class}")
    insert_record
  end

  private

  def insert_record
    parsed_message = JSON.parse(@message)
    time = parsed_message.dig("Time").in_time_zone("UTC")
    meter = parsed_message.keys.last
    reading = parsed_message.dig(meter, "reading")
    current_power = parsed_message.dig(meter, "current_power")

    case meter
    when "Haus"
      meter = "house"
    when "Solar"
      meter = "solar"
    else
      Rails.logger.warn("Unknown meter: #{meter}\nIgnoring message.")
      return
    end

    ElectricityMeterReading.create!(time:, meter:, reading:, current_power:)
  end
end
