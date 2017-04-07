require 'spec_helper'

describe Wavecrest::ErrorHandler do
  subject(:handler) { described_class.new }

  describe '#check' do
    context 'response with multiple errors' do
      it 'raises error with non-zero error codes' do
        data = {
          'errorDetails' => [
            { 'errorCode' => '100', 'errorDescription' => 'Failure' }
          ]
        }

        expect { handler.check(data) }.to raise_error do |error|
          expect(error).to be_a Wavecrest::Error
          expect(error.details).to eq [
            code: 100, description: 'Failure'
          ]
        end
      end

      it 'does not raise error with 0 error code' do
        data = {
          'errorDetails' => [
            { 'errorCode' => '0', 'errorDescription' => 'Success' }
          ]
        }

        expect { handler.check(data) }.not_to raise_error
      end

      it 'does not raise error with 130084 error code' do
        data = {
          'errorDetails' => [
            { 'errorCode' => '130084', 'errorDescription' => 'Documents for account upgrade has been received by us' }
          ]
        }

        expect { handler.check(data) }.not_to raise_error
      end
    end

    context 'response with single error' do
      it 'raises error with non-zero error codes' do
        data = {
          'errorMessage' => 'Failure',
          'errorCode' => '1001'
        }

        expect { handler.check(data) }.to raise_error do |error|
          expect(error).to be_a Wavecrest::Error
          expect(error.details).to eq [
            code: 1001, description: 'Failure'
          ]
        end
      end

      it 'does not raise error with 0 error code' do
        data = {
          'errorMessage' => 'Success',
          'errorCode' => '0'
        }

        expect { handler.check(data) }.not_to raise_error
      end
    end
  end
end
