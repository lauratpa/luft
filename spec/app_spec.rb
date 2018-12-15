require "json"

require "./luft/app"

RSpec.describe "app" do
  let(:event) do
    {
      "body" => body.to_json,
      "httpMethod" => "POST",
      "resource" => "/luft-push",
      "queryStringParameters" => nil,
      "requestContext" => {
        "httpMethod" => "POST",
        "requestId" => "c6af9ac6-7b61-11e6-9a41-93e8deadbeef",
        "path" => "/luft-push",
        "extendedRequestId" => nil,
        "resourceId" => "123456",
        "apiId" => "1234567890",
        "stage" => "prod",
        "resourcePath" => "/luft-push",
        "identity" => {
          "accountId" => nil,
          "apiKey" => nil,
          "userArn" => nil,
          "cognitoAuthenticationProvider" => nil,
          "cognitoIdentityPoolId" => nil,
          "userAgent" => "Custom User Agent String",
          "caller" => nil,
          "cognitoAuthenticationType" => nil,
          "sourceIp" => "127.0.0.1", "user" => nil,
        },
        "accountId" => "123456789012",
      },
      "headers" => {
        "Content-Length" => "445",
        "X-Forwarded-Proto" => "http",
        "X-Forwarded-Port" => "3000",
        "Content-Type" => "application/json",
        "Host" => "127.0.0.1:3000",
        "Accept" => "*/*",
        "User-Agent" => "curl/7.54.0",
      },
      "stageVariables" => nil,
      "path" => "/luft-push",
      "pathParameters" => nil,
      "isBase64Encoded" => false,
    }
  end

  let(:context) { "" }

  let(:body) do
    {
      "esp8266id" => "4620979",
      "software_version" => "NRZ-2018-121C",
      "sensordatavalues" => [
        {"value_type" => "SDS_P1",      "value" => "19.53"},
        {"value_type" => "SDS_P2",      "value" => "7.50"},
        {"value_type" => "temperature", "value" => "22.70"},
        {"value_type" => "humidity",    "value" => "39.50"},
        {"value_type" => "samples",     "value" => "914914"},
        {"value_type" => "min_micro",   "value" => "149"},
        {"value_type" => "max_micro",   "value" => "77231"},
        {"value_type" => "signal",      "value" => "-61"},
      ],
    }
  end

  let(:luft_data_record) { instance_double(LuftData) }

  it "saves the push data to dynamodb" do
    id = SecureRandom.uuid
    timestamp = Time.now.to_i

    values = SensorDataValues.new(body.fetch("sensordatavalues"))

    expect(LuftData).to receive(:new).with(
      id: id,
      timestamp: timestamp,
      pm10: values.fetch("SDS_P1"),
      pm25: values.fetch("SDS_P2"),
      temperature: values.fetch("temperature"),
      humidity: values.fetch("humidity")
    ).and_return(luft_data_record)
    expect(luft_data_record).to receive(:save!)
    expect(luft_data_record).to receive(:to_h)

    Handler.call(event: event, context: context, id: id, timestamp: timestamp)
  end
end
