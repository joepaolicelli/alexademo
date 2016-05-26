require 'sinatra'
require 'json'

post '/' do
  request.body.rewind
  @request_payload = JSON.parse request.body.read
  puts @request_payload

  # type == LaunchRequest
  if @request_payload['request']['type'] == 'LaunchRequest'
    '{
      "version": "1.0",
      "response": {
        "outputSpeech": {
          "type": "PlainText",
          "text": "Go."
        },
        "shouldEndSession": false
      }
    }'
  else
    @character_name = @request_payload['request']['intent']['slots']['Character']['value']
    puts @character_name

    '{
      "version": "1.0",
      "response": {
        "outputSpeech": {
          "type": "PlainText",
          "text": "You asked about ' + @character_name + '. The part of me that actually answers your question hasn\'t been built yet."
        },
        "shouldEndSession": true
      }
    }'
  end
end
