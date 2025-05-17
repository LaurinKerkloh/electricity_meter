require "net/http"
module LightManager
    URL = "http://192.168.0.62"
    def self.trigger_scene(scene)
      response = Net::HTTP.get(URI.join(URL,"control?scene=#{scene}"))
      return response
    end

    def self.read_marker
      response = Net::HTTP.get(URI.join(URL, "params.json"))
      return JSON.parse(response)&.dig("marker state")&.to_s.chars.map{_1 == 1}
    end
end
