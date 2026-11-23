class MqttListener
  include Singleton

  RECONNECT_DELAY = 5

  attr_accessor :host, :topics

  def start
    @thread = Thread.new do
      loop do
        Rails.logger.info("Starting MQTT listener...")
        MQTT::Client.connect(host) do |client|
          client.subscribe(*topics)

          client.get do |topic, message|
            MqttMessageHandler.new(topic, message).handle
          rescue => e
            Rails.logger.error(e)
          end
        end
      # MQTT::Exception inherits from ::Exception, not StandardError.
      rescue MQTT::Exception, StandardError => e
        Rails.logger.error("MQTT listener failed (#{e.class}: #{e.message}), reconnecting in #{RECONNECT_DELAY} s")
        sleep RECONNECT_DELAY
      end
    end
  end

  def stop
    Rails.logger.info("Stopping MQTT listener...")
    Thread.kill(@thread)
  end
end
