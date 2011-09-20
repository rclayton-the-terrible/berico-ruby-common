require_relative 'dynamic_properties'
require "date"

class WeatherObservation
  include Berico::DynamicProperties

  def initialize
    @date_time = ::DateTime.now
  end

  def to_s
    output = "Weather Observation \n"
    output << "  Time: #{@date_time}\n"
    @properties.each do |key, value|
       output << "  #{key}: #{value}\n"
    end
    output
  end
end

observation = WeatherObservation.new

observation.temperature = 75
observation.dew_point = 25
observation.wind_speed = 10
observation.wind_dir = 270
observation.visibility = 10
observation.sky_con = :clear
observation.altimeter = 29.92

puts observation