return unless Rails.env.production? || Rails.env.development?

begin
  Thread.new do
    Rails.logger.info("Starting MQTT listener...")
    client = MQTT::Client.connect("192.168.0.122")

    client.subscribe("tele/Haus/SENSOR", "tele/Solar/SENSOR")

    client.get do |topic, message|
      # Rails.logger.debug { "Received message on topic #{topic}: #{message}" }
      MqttHandler.new(topic, message).handle
    end
  end
rescue => e
  Rails.logger.error("Error in MQTT listener: #{e.message}")
  retry
end
