require 'spec_helper'
require 'securerandom'

describe Wavecrest do
  subject(:wavecrest) { described_class }

  let(:user_id) { 'whatever_user_id' }
  let(:proxy) { 'whatever_proxy' }
  let(:partner_id) { wavecrest.configuration.partner_id }

  describe '.countries' do
    it 'returns list of countries' do
      expect(wavecrest.countries).to be_a Array
    end
  end

  describe '.card_status' do
    it 'returns list of card statuses' do
      expect(wavecrest.card_status).to be_a Array
    end
  end

  describe '.auth' do
    let(:response) { { token: SecureRandom.hex }.to_json }
    let(:headers) do
      {
        'Content-Type': 'application/json',
        'DeveloperId': wavecrest.configuration.user,
        'DeveloperPassword': wavecrest.configuration.password,
        'X-Method-Override': 'login'
      }
    end
    let!(:request) do
      stub_post('authenticator')
        .with(body: '', headers: headers)
        .to_return(body: response)
    end

    it 'requests auth token' do
      wavecrest.auth
      expect(request).to have_been_made
    end

    it 'authenticates client for 1 hour' do
      wavecrest.auth
      expect(wavecrest).not_to be_auth_need

      Timecop.travel(1.hour) do
        expect(wavecrest).to be_auth_need
      end
    end
  end

  describe '.send_request' do
    context 'unauthenticated' do
      let!(:request) { stub_post('cards').to_return(body: success_response) }

      before do
        allow(wavecrest).to receive(:auth)
        stub_auth_need(true)
      end

      it 'authenticates client' do
        expect(wavecrest).to receive(:auth)
        wavecrest.send_request(:post, '/cards')
      end

      it 'performs request' do
        wavecrest.send_request(:post, '/cards')
        expect(request).to have_been_made
      end
    end

    context 'authenticated' do
      let!(:request) { stub_post('cards').to_return(body: success_response) }

      before { stub_auth_need(false) }

      it 'performs request' do
        wavecrest.send_request(:post, '/cards')
        expect(request).to have_been_made
      end
    end

    context 'verbs' do
      let(:token) { SecureRandom.hex }
      let(:params) { { whatever: 'whatever' } }
      let(:headers) do
        {
          'Content-Type': 'application/json',
          'DeveloperId': wavecrest.configuration.user,
          'DeveloperPassword': wavecrest.configuration.password,
          'AuthenticationToken': token
        }
      end

      before do
        stub_auth_need(true)
        stub_post('authenticator').to_return(body: { token: token }.to_json)
      end

      it 'performs GET requests' do
        request = stub_wavecrest_request(:get, 'cards').to_return(body: success_response)
        wavecrest.send_request(:get, '/cards')

        expect(request).to have_been_made
      end

      it 'performs POST requests' do
        request = stub_wavecrest_request(:post, 'cards')
          .with(body: params.to_json, headers: headers)
          .to_return(body: success_response)

        wavecrest.send_request(:post, '/cards', params)

        expect(request).to have_been_made
      end

      it 'performs DELETE requests' do
        request = stub_wavecrest_request(:delete, 'cards')
          .with(body: params.to_json)
          .to_return(body: success_response)

        wavecrest.send_request(:delete, '/cards', params)

        expect(request).to have_been_made
      end

      it 'performs PUT requests' do
        request = stub_wavecrest_request(:put, 'cards')
          .with(body: params.to_json)
          .to_return(body: success_response)
        wavecrest.send_request(:put, '/cards', params)

        expect(request).to have_been_made
      end

      it 'fails with unknown verbs' do
        expect {
          wavecrest.send_request(:patch, '/cards')
        }.to raise_error(/Unsupported/)
      end
    end
  end

  describe 'API methods' do
    before { stub_auth_need(false) }

    describe '.request_card' do
      let!(:request) { stub_post('cards').to_return(body: success_response) }

      it 'requests card' do
        wavecrest.request_card(nameOnCard: 'JOHN DOE')
        expect(request).to have_been_made
      end
    end

    describe '.load_money' do
      let!(:request) { stub_post("users/#{user_id}/cards/#{proxy}/load").to_return(body: success_response) }

      it 'loads money' do
        wavecrest.load_money(user_id, proxy, whatever: 'whatever')
        expect(request).to have_been_made
      end
    end

    describe '.balance' do
      let(:response) { success_response(avlBal: '42') }
      let!(:request) { stub_get("users/#{user_id}/cards/#{proxy}/balance").to_return(body: response) }

      it 'fetches balance' do
        result = wavecrest.balance(user_id, proxy)

        expect(request).to have_been_made
        expect(result).to eq 42
      end
    end

    describe '.details' do
      let!(:request) { stub_get("users/#{user_id}/cards/#{proxy}/carddetails").to_return(body: success_response) }

      it 'fetches card details' do
        wavecrest.details(user_id, proxy)
        expect(request).to have_been_made
      end
    end

    describe '.transactions' do
      let!(:request) { stub_post("users/#{user_id}/cards/#{proxy}/transactions").to_return(body: success_response) }

      it 'fetches card transactions' do
        wavecrest.transactions(user_id, proxy)
        expect(request).to have_been_made
      end
    end

    describe '.prefunding_account' do
      let!(:request) { stub_post("businesspartners/#{partner_id}/balance").to_return(body: success_response) }

      it 'fetches prefunding account' do
        wavecrest.prefunding_account('USD')
        expect(request).to have_been_made
      end
    end

    describe '.prefunding_accounts' do
      let(:response) { success_response(txnAccountList: [42]) }
      let!(:request) { stub_get("businesspartners/#{partner_id}/txnaccounts").to_return(body: response) }

      it 'fetches prefunding accounts' do
        result = wavecrest.prefunding_accounts

        expect(request).to have_been_made
        expect(result).to eq [42]
      end
    end

    describe '.prefunding_transactions' do
      let(:account_id) { 'whatever_account_id' }
      let!(:request) do
        stub_get("businesspartners/#{partner_id}/transactionaccounts/#{account_id}/transfers")
          .to_return(body: success_response)
      end

      it 'fetches prefunding transactions' do
        wavecrest.prefunding_transactions(account_id)
        expect(request).to have_been_made
      end
    end

    describe '.activate' do
      let!(:request) { stub_post("users/#{user_id}/cards/#{proxy}/activate").to_return(body: success_response) }

      it 'activates card' do
        wavecrest.activate(user_id, proxy, whatever: 'whatever')
        expect(request).to have_been_made
      end
    end

    describe '.cardholder' do
      let!(:request) { stub_get("users/#{user_id}/cards/#{proxy}/cardholderinfo").to_return(body: success_response) }

      it 'fetches cardholder info' do
        wavecrest.cardholder(user_id, proxy)
        expect(request).to have_been_made
      end
    end

    describe '.upload_docs' do
      let!(:request) { stub_post("users/#{user_id}/kyc").to_return(body: success_response) }

      it 'uploads docs' do
        wavecrest.upload_docs(user_id, whatever: 'whatever')
        expect(request).to have_been_made
      end
    end

    describe '.update_status' do
      let!(:request) { stub_post("users/#{user_id}/cards/#{proxy}/status").to_return(body: success_response) }

      it 'updates card status' do
        wavecrest.update_status(user_id, proxy, whatever: 'whatever')
        expect(request).to have_been_made
      end
    end

    describe '.user_details' do
      let!(:request) { stub_get("users/#{user_id}").to_return(body: success_response) }

      it 'fetches user details' do
        wavecrest.user_details(user_id)
        expect(request).to have_been_made
      end
    end

    describe '.replace' do
      let!(:request) { stub_post("users/#{user_id}/cards/#{proxy}/replace").to_return(body: success_response) }

      it 'replaces card' do
        wavecrest.replace(user_id, proxy, whatever: 'whatever')
        expect(request).to have_been_made
      end
    end

    describe '.transfer' do
      let!(:request) { stub_post("cards/#{proxy}/transfers").to_return(body: success_response) }

      it 'transfers money' do
        wavecrest.transfer(user_id, proxy, whatever: 'whatever')
        expect(request).to have_been_made
      end
    end

    describe '.change_user_password' do
      let!(:request) { stub_post("users/#{user_id}/createPassword").to_return(body: success_response) }

      it 'changes user password' do
        wavecrest.change_user_password(user_id, whatever: 'whatever')
        expect(request).to have_been_made
      end
    end

    describe '.update_card' do
      let!(:request) { stub_post("users/#{user_id}/cards/#{proxy}/").to_return(body: success_response) }

      it 'updates card' do
        wavecrest.update_card(user_id, proxy, whatever: 'whatever')
        expect(request).to have_been_made
      end
    end

    describe '.card_unload' do
      let!(:request) { stub_post("users/#{user_id}/cards/#{proxy}/purchase").to_return(body: success_response) }

      it 'unloads money' do
        wavecrest.card_unload(user_id, proxy, whatever: 'whatever')
        expect(request).to have_been_made
      end
    end
  end

  def stub_auth_need(auth_need)
    allow(wavecrest).to receive(:auth_need?).and_return(auth_need)
  end
end
