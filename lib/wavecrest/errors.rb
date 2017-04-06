module Wavecrest
  class Exception < StandardError
  end

  class Error < Wavecrest::Exception
    attr_reader :details

    def initialize(details)
      @details = details
    end

    def to_s
      details.map { |error| "[#{error[:code]}] #{error[:description]}" }.join(', ')
    end
  end
end
