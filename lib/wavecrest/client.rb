require 'wavecrest/error_handler'

module Wavecrest
  class Client
    DEFAULT_HEADERS = {
      'Content-Type' => 'application/json'.freeze,
      'Accept' => 'application/json'.freeze
    }.freeze

    attr_reader :configuration, :error_handler

    def initialize(configuration)
      @configuration = configuration
      @error_handler = ErrorHandler.new
    end

    def call(method:, path:, params: {}, headers: {})
      url = URI.join(configuration.endpoint, File.join('/v3/services/', path))

      http = build_http(url)
      request = build_request(method, url, params, headers)
      response = http.request(request)

      parse_response(response)
    end

    private

    # rubocop:disable Metrics/AbcSize
    def build_http(url)
      if configuration.proxy
        proxy_uri = URI.parse(configuration.proxy)
        http = Net::HTTP.new(url.host, url.port, proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
      else
        http = Net::HTTP.new(url.host, url.port)
      end

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

    def parse_response(response)
      data = JSON.parse(response.body)
      error_handler.check(data)
      data
    end
  end
end
