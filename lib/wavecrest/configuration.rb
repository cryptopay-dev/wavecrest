module Wavecrest
  class Configuration
    attr_accessor :endpoint, :user, :password, :partner_id, :proxy
    attr_accessor :open_timeout, :read_timeout

    DEFAULT_TIMEOUT = 30.seconds

    def initialize
      self.open_timeout = DEFAULT_TIMEOUT
      self.read_timeout = DEFAULT_TIMEOUT
    end
  end
end
