if defined?(Rails::Server)
  Rails.application.config.after_initialize do
    listener = MqttListener.instance
    listener.host = "192.168.0.122"
    listener.topics = ["tele/Haus/SENSOR", "tele/Solar/SENSOR"]
    listener.start
  end

  at_exit do
    MqttListener.instance.stop
  end
end
