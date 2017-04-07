module Wavecrest
  class ErrorHandler
    SUCCESS_CODES = [
      0,
      130084 # Successful documents submission
    ].freeze

    def check(data)
      check_for_multiple_errors(data)
      check_for_single_error(data)
    end

    private

    # {
    #   'errorDetails' => [
    #     {
    #       'errorCode' => '1162',
    #       'errorDescription' => 'Currency is not valid'
    #     }
    #   ]
    # }
    def check_for_multiple_errors(data)
      return if data['errorDetails'].blank?

      errors = data['errorDetails']
      code = errors.first['errorCode'].to_i

      return if SUCCESS_CODES.include?(code)

      details = errors.map do |error|
        { code: error['errorCode'].to_i, description: error['errorDescription'] }
      end
      raise Error, details
    end

    # {
    #   'errorMessage' => 'Invalid Enum Value in the request - Index: 0, Size: 0',
    #   'errorCode' => '1001'
    # }
    def check_for_single_error(data)
      message = data['errorMessage']
      code = data['errorCode'].to_i

      return if SUCCESS_CODES.include?(code)

      details = [{ code: code, description: message }]
      raise Error, details
    end
  end
end
