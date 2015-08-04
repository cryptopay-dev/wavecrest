require 'rest_client'
require 'net/http'
require 'json'
require "wavecrest/version"
require "wavecrest/configuration"


module Wavecrest
  # autoload :Wavecrest, 'wavecrest'
  class << self
    attr_accessor :configuration, :auth_token, :auth_token_issued
  end

  def self.configure
    self.configuration ||= Wavecrest::Configuration.new
    yield(configuration)
  end

  def self.countries
    [
        'AX', 'AL', 'AD', 'AI', 'AG', 'AR', 'AM', 'AW', 'AU', 'AT', 'BS', 'BH', 'BB', 'BY', 'BE', 'BZ', 'BM', 'BT',
        'BQ', 'BA', 'BR', 'BN', 'BG', 'CA', 'CV', 'KY', 'CL', 'CN', 'CO', 'CR', 'HR', 'CW', 'CY', 'CZ', 'DK', 'DM',
        'DO', 'EC', 'SV', 'EE', 'FK', 'FO', 'FI', 'FR', 'GF', 'GE', 'DE', 'GI', 'GR', 'GL', 'GD', 'GP', 'GT', 'GG',
        'GY', 'HK', 'HU', 'IS', 'ID', 'IE', 'IM', 'IL', 'IT', 'JM', 'JP', 'JE', 'JO', 'KZ', 'KR', 'XK', 'KW', 'LV',
        'LI', 'LT', 'LU', 'MK', 'MY', 'MV', 'MT', 'MQ', 'MU', 'YT', 'MX', 'MD', 'MC', 'MN', 'ME', 'MA', 'NP', 'NL',
        'NZ', 'NI', 'NO', 'OM', 'PA', 'PG', 'PY', 'PE', 'PH', 'PL', 'PT', 'QA', 'RE', 'RO', 'RU', 'BL', 'KN', 'LC',
        'MF', 'VC', 'SM', 'SA', 'RS', 'SC', 'SG', 'SX', 'SK', 'SI', 'ZA', 'ES', 'SR', 'SE', 'CH', 'TW', 'TH', 'TT',
        'TR', 'TC', 'UA', 'AE', 'GB', 'UY', 'VE', 'VG'
    ]
  end

  def self.auth_need?
    return true unless auth_token
    return true if auth_token_issued.kind_of?(Time) and auth_token_issued + 1.hour < Time.now
  end

  def self.auth
    url = configuration.endpoint + "/v3/services/authenticator"

    headers = {
        "DeveloperId" => configuration.user,
        "DeveloperPassword" => configuration.password,
        "X-Method-Override" => 'login',
        accept: :json,
        content_type: :json
    }

    RestClient.proxy = configuration.proxy if configuration.proxy
    request = RestClient::Request.new(method: :post, url: url, headers: headers)
    response = request.execute.body
    data = JSON.parse response
    self.auth_token = data["token"]
    self.auth_token_issued = Time.now
  end


  def self.send_request method, path, params={}
    auth if auth_need?

    url = configuration.endpoint + "/v3/services" + path
    payload = params.to_json
    headers = {
        "DeveloperId" => configuration.user,
        "DeveloperPassword" => configuration.password,
        "AuthenticationToken" => auth_token,
        accept: :json,
        content_type: :json
    }

    begin
      RestClient.proxy = configuration.proxy if configuration.proxy
      request = RestClient::Request.new(method: method, url: url, payload: payload, headers: headers)
      response = request.execute.body
      RestClient.proxy = nil
      JSON.parse response
    rescue => e
      puts e.message, e.response
      return JSON.parse e.response
    end
  end


  def self.request_card(params)
    default_params = {
        "cardProgramId" => "0",
        "Businesspartnerid" => configuration.partner_id,
        "channelType" => "1",
        # "deliveryType" => 'Standard Delivery Type',
        "localeTime" => Time.now
    }
    payload = default_params.merge params
    send_request :post, "/cards", payload
  end

  def self.load_money(user_id, proxy, params= {})
    default_params = {
        "channelType" => "1",
        "agentId" => configuration.partner_id
    }
    payload = default_params.merge params
    send_request :post, "/users/#{user_id}/cards/#{proxy}/load", payload
  end

  def self.balance user_id, proxy
    resp = send_request :get, "/users/#{user_id}/cards/#{proxy}/balance"
    resp['avlBal'].to_i
  end


  def self.details user_id, proxy
    send_request :get, "/users/#{user_id}/cards/#{proxy}/carddetails"
  end

  def self.transactions user_id, proxy
    send_request :post, "/users/#{user_id}/cards/#{proxy}/transactions", {txnCount: 10000}
  end
end
