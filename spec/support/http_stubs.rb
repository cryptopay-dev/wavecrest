def stub_get(path)
  stub_wavecrest_request(:get, path)
end

def stub_post(path)
  stub_wavecrest_request(:post, path)
end

def success_response(attributes = {})
  {
    errorDetails: [
      { errorCode: '0', errorDescription: 'Success' }
    ]
  }.merge(attributes).to_json
end

def stub_wavecrest_request(verb, path)
  stub_request(verb, "#{Wavecrest.configuration.endpoint}/v3/services/#{path}")
end
