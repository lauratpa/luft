require "aws-record"
require "securerandom"
require "json"

class LuftData
  include Aws::Record
  set_table_name ENV["DDB_TABLE"]

  string_attr :id, hash_key: true
  epoch_time_attr :timestamp
  float_attr :pm10
  float_attr :pm25
  float_attr :temperature
  float_attr :humidity
end

class SensorDataValues
  def initialize(values)
    @values = values
  end

  def fetch(key)
    values.detect { |el| el.fetch("value_type") == key }.fetch("value")
  end

  private

  attr_reader :values
end

class Handler
  def self.call(event:, context:, id: SecureRandom.uuid, timestamp: Time.now.to_i)
    body = JSON.parse(event.fetch("body"))
    values = SensorDataValues.new(body.fetch("sensordatavalues"))

    item = LuftData.new(
      id: id,
      timestamp: timestamp,
      pm10: values.fetch("SDS_P1"),
      pm25: values.fetch("SDS_P2"),
      temperature: values.fetch("temperature"),
      humidity: values.fetch("humidity")
    )
    item.save!

    {
      statusCode: 200,
      body: item.to_h.to_json,
    }
  end
end
