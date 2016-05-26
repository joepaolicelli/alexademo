require 'sinatra'
require 'json'

post '/' do
  request.body.rewind
  @request_payload = JSON.parse request.body.read
  puts @request_payload

  # type == LaunchRequest
  if @request_payload['request']['type'] == 'LaunchRequest'
    launch_response = {
      "version" => "1.0",
      "response" => {
        "outputSpeech" => {
          "type" => "PlainText",
          "text" => "Go."
        },
        "shouldEndSession" => false
      }
    }
    JSON.generate(launch_response)
  else
    @character_name =
     @request_payload['request']['intent']['slots']['Character']['value']
    puts @character_name

    character_response = {
      "version" => "1.0",
      "response" => {
        "outputSpeech" => {
          "type" => "PlainText",
          "text" => "You asked about #{@character_name}. They're awesome!"
        },
        "shouldEndSession": true
      }
    }
    JSON.generate(character_response)
  end
end
