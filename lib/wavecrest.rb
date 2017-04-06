require 'net/http'
require 'json'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/string/inflections'
require 'wavecrest/version'
require 'wavecrest/configuration'
require 'wavecrest/errors'
require 'wavecrest/client'

module Wavecrest # rubocop:disable Metrics/ModuleLength
  extend self

  COUNTRIES = %w(
    AX AL AD AI AG AR AM AW AU AT AZ BS BH BB BY BE BZ BM BT BQ BA BR BN BG
    CA KY CL CN CO

    CR HR CY CZ DK DM DO EC SV EE FK FO FI FR GF GE DE GI GR
    GL GD GP GT GG GY HK HU IS ID IE IM IL IT JM JP JE JO KZ KR QZ KW LV LI LT

    LU MK MY MV MT MQ MU MX MD MC MN ME MA NP NL NZ NI NO OM PA PG PY PE PH
    PL PT QA RO RU BL KN LC MF VC SM SA RS SC SG SX SK SI SB ZA

    ES SR SE CH TW TH TT TR TC UA AE GB UY VG
  ).freeze

  CARD_STATUSES = %w(
    READY_TO_ACTIVE
    READY_FOR_AE
    Intermediate_Assignment
    ACTIVE
    EXPIRED
    LOST
    STOLEN
    DESTROYED
    DAMAGED
    DORMANT
    CLOSED
    REPLACED
    SUSPENDED
    SACTIVE
    REVOKED
    CCLOSED
    MBCLOSED
    FRAUD
    PFRAUD
    CHARGEOFF
    DECEASED
    WARNING
    MUCLOSED
    VOID
    NONRENEWAL
    LAST_STMT
    INACTIVE
    BLOCKED
    DEACTIVATE
    ENABLE
    UNSUSPEND
  ).freeze

  class << self
    attr_accessor :configuration
  end

  def configure
    self.configuration ||= Wavecrest::Configuration.new
    yield(configuration)
  end

  def countries
    COUNTRIES
  end

  def card_status
    CARD_STATUSES
  end

  def auth_token
    ENV['_WAVECREST_AUTH_TOKEN']
  end

  def auth_need?
    auth_token_issued_at = Time.at(ENV['_WAVECREST_AUTH_TOKEN_ISSUED'].to_i)
    return true unless auth_token
    return true if auth_token_issued_at.is_a?(Time) && auth_token_issued_at + 1.hour < Time.now
  end

  def auth
    data = client.call(method: :post, path: '/authenticator', headers: {
      'DeveloperId' => configuration.user,
      'DeveloperPassword' => configuration.password,
      'X-Method-Override' => 'login'
    })

    ENV['_WAVECREST_AUTH_TOKEN'] = data['token']
    ENV['_WAVECREST_AUTH_TOKEN_ISSUED'] = Time.now.to_i.to_s
  end

  def send_request(method, path, params = {})
    auth if auth_need?

    client.call(method: method, path: path, params: params, headers: {
      'DeveloperId' => configuration.user,
      'DeveloperPassword' => configuration.password,
      'AuthenticationToken' => auth_token
    })
  end

  def request_card(params)
    default_params = {
      'cardProgramId' => '0',
      'Businesspartnerid' => configuration.partner_id,
      'channelType' => '1',
      'localeTime' => Time.now
    }
    payload = default_params.merge(params)
    send_request(:post, '/cards', payload)
  end

  def load_money(user_id, proxy, params = {})
    default_params = {
      'channelType' => '1',
      'agentId' => configuration.partner_id
    }
    payload = default_params.merge(params)
    send_request(:post, "/users/#{user_id}/cards/#{proxy}/load", payload)
  end

  def balance(user_id, proxy)
    resp = send_request :get, "/users/#{user_id}/cards/#{proxy}/balance"
    resp['avlBal'].to_i
  end

  def details(user_id, proxy)
    send_request(:get, "/users/#{user_id}/cards/#{proxy}/carddetails")
  end

  def transactions(user_id, proxy, count: 100, offset: 0)
    payload = { txnCount: count, offset: offset }
    send_request(:post, "/users/#{user_id}/cards/#{proxy}/transactions", payload)
  end

  def prefunding_account(currency = 'EUR')
    send_request(:post, "/businesspartners/#{configuration.partner_id}/balance", currency: currency)
  end

  def prefunding_accounts
    resp = send_request(:get, "/businesspartners/#{configuration.partner_id}/txnaccounts")
    resp['txnAccountList']
  end

  def prefunding_transactions(account_id)
    send_request(:get, "/businesspartners/#{configuration.partner_id}/transactionaccounts/#{account_id}/transfers")
  end

  def activate(user_id, proxy, payload)
    send_request(:post, "/users/#{user_id}/cards/#{proxy}/activate", payload)
  end

  def cardholder(user_id, proxy)
    send_request(:get, "/users/#{user_id}/cards/#{proxy}/cardholderinfo")
  end

  def upload_docs(user_id, payload)
    send_request(:post, "/users/#{user_id}/kyc", payload)
  end

  def update_status(user_id, proxy, payload)
    send_request(:post, "/users/#{user_id}/cards/#{proxy}/status", payload)
  end

  def user_details(user_id)
    send_request(:get, "/users/#{user_id}")
  end

  def replace(user_id, proxy, payload)
    send_request(:post, "/users/#{user_id}/cards/#{proxy}/replace", payload)
  end

  def transfer(_user_id, proxy, payload)
    send_request(:post, "/cards/#{proxy}/transfers", payload)
  end

  def change_user_password(user_id, payload)
    send_request(:post, "/users/#{user_id}/createPassword", payload)
  end

  def update_card(user_id, proxy, payload)
    send_request(:post, "/users/#{user_id}/cards/#{proxy}/", payload)
  end

  def card_unload(user_id, proxy, payload)
    send_request(:post, "/users/#{user_id}/cards/#{proxy}/purchase", payload)
  end

  private

  def client
    Client.new(configuration)
  end
end
