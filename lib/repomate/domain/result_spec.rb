# frozen_string_literal: true

require 'spec_helper'
require_relative './result'

describe Repomate::Domain::Result do
  describe '.success' do
    it 'creates a successful result' do
      result = described_class.success('Operation completed')
      expect(result).to be_success
      expect(result.message).to eq('Operation completed')
    end

    it 'accepts nil message' do
      result = described_class.success(nil)
      expect(result).to be_success
      expect(result.message).to be_nil
    end
  end

  describe '.failure' do
    it 'creates an unsuccessful result' do
      result = described_class.failure('Operation failed')
      expect(result).not_to be_success
      expect(result.message).to eq('Operation failed')
    end

    it 'accepts empty message' do
      result = described_class.failure('')
      expect(result).not_to be_success
      expect(result.message).to eq('')
    end
  end
end
