class MqttListener
  include Singleton

  attr_accessor :host, :topics

  def start
    @thread = Thread.new do
      Rails.logger.info("Starting MQTT listener...")
      client = MQTT::Client.connect(host)

      client.subscribe(*topics)

      client.get do |topic, message|
        MqttMessageHandler.new(topic, message).handle
      rescue => e
        Rails.logger.error(e)
      end
    end
  end

  def stop
    Rails.logger.info("Stopping MQTT listener...")
    Thread.kill(@thread)
  end
end
