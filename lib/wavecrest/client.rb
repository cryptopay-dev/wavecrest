require 'active_support/core_ext/object/blank'

module Wavecrest
  class Client
    DEFAULT_HEADERS = {
      'Content-Type' => 'application/json'.freeze,
      'Accept' => 'application/json'.freeze
    }.freeze

    REQUEST_CLASSES = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      delete: Net::HTTP::Delete,
      put: Net::HTTP::Put
    }.freeze

    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def call(method:, path:, params: {}, headers: {})
      url = URI.join(configuration.endpoint, File.join('/v3/services/', path))

      http = build_http(url)
      request = build_request(method, url, params, headers)
      response = http.request(request)

      JSON.parse(response.body)
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
      klass = REQUEST_CLASSES.fetch(method) do
        raise "Unsupported request method #{method}"
      end

      request = klass.new(url.request_uri)
      request.body = params.to_json if params.present? && method != :get

      DEFAULT_HEADERS.merge(headers).each do |key, value|
        request.add_field(key, value)
      end

      request
    end
  end
end
