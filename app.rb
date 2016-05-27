require 'digest'
require 'json'
require 'rest-client'
require 'sinatra'

require './apis/marvel'

configure do
  set :root, File.dirname(__FILE__)

  @marvel = Marvel.new
end



post '/' do
  request.body.rewind
  request_payload = JSON.parse request.body.read

  puts "REQUEST:\n"
  puts request_payload

  # type == LaunchRequest
  if request_payload['request']['type'] == 'LaunchRequest'
    launch_response = {
      "version" => "1.0",
      "response" => {
        "outputSpeech" => {
          "type" => "PlainText",
          "text" => "What would you like to know?"
        },
        "shouldEndSession" => false
      }
    }
    return JSON.generate(launch_response)
  else

    # Get intent, send to appropriate method.
    intent = request_payload['request']['intent']['name']

    if intent == "GetBasicInfo"
      res = get_basic_info(request_payload)
    else
      res = {}
    end

    return res
  end
end

def get_basic_info(req)

  subject = req['request']['intent']['slots']['Character']['value']

  params = {
    'name' => subject
  }

  api_res = @marvel.query("characters", params)

  puts api_res
  $stdout.flush

  res = {}

  if api_res["code"] != 200
    res = build_res_obj("Error", "An error occured. Please ask Tony Stark to fix the issue.")
  elsif api_res["code"] == 200 && api_res["data"]["total"] == 1
    source_text = api_res["data"]["results"][0]["description"]
    if source_text == ""
      source_text = "There is no description available for this character... or maybe Hydra deleted it."
    end
    attribution = api_res["attributionHTML"]
    thumbnail = api_res["data"]["results"][0]["thumbnail"]
    if thumbnail != nil
      thumbnail = thumbnail[path] + "/standard_fantastic." + thumbnail[extension]
    end
    res = build_res_obj(subject, source_text, attribution, thumbnail)
  elsif api_res["code"] == 200 && api_res["data"]["total"] == 0
    res = build_res_obj("No Information Found", "I could not find any information about #{subject}.")
  else
    res = build_res_obj("Multiple Matches Found", "I found multiple possible matches for #{subject}.")
  end

  return JSON.generate(res)
end

# card_text and card_image are optional.
# If nothing is passed, card_text will be the same as speech_text.
# For no card text, pass an empty string.
def build_res_obj(card_title, speech_text, attribution = "", card_image = nil, card_text = nil,)
  res = {
    "version" => "1.0",
    "response" => {
      "outputSpeech" => {
        "type" => "PlainText",
        "text" => speech_text
      },
      "card" => {
        "title" => card_title
      },
      "shouldEndSession" => true
    }
  }

  if card_text == nil
    card_text = speech_text
  end

  if attribution != ""
    card_text += "\n\n" + attribution
  end

  if card_image == nil
    res["response"]["card"]["type"] = "Simple"
    res["response"]["card"]["content"] = card_text
  else
    res["response"]["card"]["type"] = "Standard"
    res["response"]["card"]["text"] = card_text
    res["response"]["card"]["image"]["largeImageUrl"] = card_image
  end

  return res
end
