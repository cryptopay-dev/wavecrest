require "cryptopay/version"
require 'rest_client'
require 'net/http'
require 'cryptopay/net'
require 'json'

module Wavecrest


  def initialize options={}
    @endpoint = URI.parse options[:endpoint]
  end

  def self.configure
    self.configuration ||= Wavecrest::Configuration.new
    yield(configuration)
  end


  def send_request method, path, params={}
    endpoint = ENV['WAVECREST_ENDPOINT']
    url = endpoint + "/v3/services" + path
    payload = params.to_json
    raise Exception if @@retries > 3

    headers = {
        "DeveloperId" => ENV['WAVECREST_USER'],
        "DeveloperPassword" => ENV['WAVECREST_PASSWORD'],
        "X-Method-Override" => 'login',
        "AuthenticationToken" => @auth_token,
        accept: :json,
        content_type: :json
    }

    begin
      RestClient.proxy = ENV['BITGO_PROXY']
      request = RestClient::Request.new(method: method, url: url, payload: payload, headers: headers)
      response = request.execute.body
      RestClient.proxy = nil
      @@retries = 0
      JSON.parse response
    rescue => e
      @@retries+=1
      if e.response and e.response.code == 401 #auth and call again
        auth
        send_request method, path, params
      else
        puts e.message, e.response
        return JSON.parse e.response
      end

    end
  end
end
