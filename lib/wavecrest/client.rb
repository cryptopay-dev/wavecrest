require 'wavecrest/error_handler'
require 'active_support/notifications'

module Wavecrest
  class Client
    DEFAULT_HEADERS = {
      'Content-Type' => 'application/json'.freeze,
      'Accept' => 'application/json'.freeze
    }.freeze

    attr_reader :configuration, :error_handler

    delegate :instrument, to: ActiveSupport::Notifications

    def initialize(configuration)
      @configuration = configuration
      @error_handler = ErrorHandler.new
    end

    # rubocop:disable Metrics/ParameterLists
    def call(operation:, method:, path:, params: {}, headers: {}, read_timeout: nil, open_timeout: nil)
      url = URI.join(configuration.endpoint, File.join('/v3/services/', path))

      http = build_http(url, read_timeout: read_timeout, open_timeout: open_timeout)
      request = build_request(method, url, params, headers)
      response = with_request_instrumentation(operation) { http.request(request) }

      check_response_error(response)
      parse_response(response)
    end
    # rubocop:enable Metrics/ParameterLists

    private

    # rubocop:disable Metrics/AbcSize
    def build_http(url, read_timeout: nil, open_timeout: nil)
      if configuration.proxy
        proxy_uri = URI.parse(configuration.proxy)
        http = Net::HTTP.new(url.host, url.port, proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
      else
        http = Net::HTTP.new(url.host, url.port)
      end

      http.open_timeout = open_timeout || configuration.open_timeout
      http.read_timeout = read_timeout || configuration.read_timeout
      http.use_ssl = true if url.scheme == 'https'

      http
    end
    # rubocop:enable Metrics/AbcSize

    def build_request(method, url, params, headers)
      klass = "Net::HTTP::#{method.to_s.camelize}".safe_constantize
      raise "Unsupported request method #{method}" unless klass

      request = klass.new(url.request_uri)
      request.body = params.to_json if params.present? && method != :get

      DEFAULT_HEADERS.merge(headers).each do |key, value|
        request.add_field(key, value)
      end

      request
    end

    def check_response_error(response)
      response.error! if response.is_a?(Net::HTTPServerError)
    end

    def parse_response(response)
      data = JSON.parse(response.body)
      error_handler.check(data)
      data
    rescue JSON::ParserError
      raise Wavecrest::Exception, "#{response.code}: malformed response"
    end

    def with_request_instrumentation(operation) # rubocop:disable Metrics/MethodLength
      start_time = Time.current

      response = yield

      instrument(
        'request.wavecrest',
        response_time: Time.current - start_time,
        response_code: response.code.to_i,
        operation: operation
      )

      response
    rescue Net::HTTPServerException => e
      instrument(
        'request.wavecrest',
        response_time: Time.current - start_time,
        response_code: e.response.code.to_i,
        operation: operation
      )
      raise
    end
  end
end
