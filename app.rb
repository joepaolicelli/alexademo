require 'sinatra'
require 'json'
require 'rest-client'
require 'digest'

configure do
  set :root, File.dirname(__FILE__)
end

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

    character_description = get_character_description(@character_name)

    character_response = {
      "version" => "1.0",
      "response" => {
        "outputSpeech" => {
          "type" => "PlainText",
          "text" => character_description
        },
        "shouldEndSession": true
      }
    }
    JSON.generate(character_response)
  end
end

def get_character_description(character_name)

  params = {
    'name' => character_name
  }

  api_res = query_marvel_api("characters", params)

  if(api_res["code"] == 200 && api_res["data"]["total"] == 1)
    response = api_res["data"]["results"]["description"]
  elsif(api_res["code"] == 200 && api_res["data"]["total"] == 0)
    response = "I found no characters with that name."
  elsif(api_res["code"] == 200)
    response = "Multiple characters matching that name were found."
  else
    response = "An error occured. Please ask Tony Stark to fix the issue."
  end

  return response
end

def query_marvel_api(path, params)

  request_url = "http://gateway.marvel.com:80/v1/public/" + path

  timestamp = Time.now.to_i.to_s # .to_i returns unix timestamp, .to_s makes it a string

  params["ts"] = timestamp
  params["apikey"] = ENV['MARVEL_PUB_KEY']
  params["hash"] = Digest::MD5.digest(timestamp + ENV['MARVEL_PRI_KEY'] + ENV['MARVEL_PUB_KEY'])

  params = {
    :params => params
  }

  puts "LOOK HERE!"
  puts request_url
  #return JSON.parse((RestClient.get request_url, params).body)
end
