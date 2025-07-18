# frozen_string_literal: true

require 'fileutils'
require 'spec_helper'
require_relative './operations'

describe Repomate::Infra::Git::Operations do
  let(:repository) { double('repository') }

  describe '.update' do
    it 'updates the repository successfully' do
      allow(repository).to receive(:path).and_return('/path/to/repo')
      allow(Dir).to receive(:chdir).and_yield
      allow(described_class).to receive(:system).and_return(true)

      expect { described_class.update(repository) }.not_to raise_error
    end

    it 'raises an error when update fails' do
      allow(repository).to receive(:path).and_return('/path/to/repo')
      allow(Dir).to receive(:chdir).and_yield
      allow(described_class).to receive(:system).and_return(false)

      expect(described_class.update(repository)).to eq(false)
    end
  end

  describe '.clone' do
    it 'clones the repository successfully' do
      allow(repository).to receive(:url).and_return('git@github.com:user/repo.git')
      allow(repository).to receive(:path).and_return('/path/to/clone')
      allow(described_class).to receive(:system).and_return(true)

      expect { described_class.clone(repository) }.not_to raise_error
    end

    it 'raises an error when clone fails' do
      allow(repository).to receive(:url).and_return('git@github.com:user/repo.git')
      allow(repository).to receive(:path).and_return('/path/to/clone')
      allow(described_class).to receive(:system).and_return(false)

      expect do
        described_class.clone(repository)
      end.to raise_error(Repomate::Infra::Git::Operations::Error,
                         'Failed to clone repository')
    end
  end

  describe '.remove' do
    it 'removes the repository successfully' do
      allow(repository).to receive(:path).and_return('/path/to/repo')
      allow(repository).to receive(:exists_locally?).and_return(false)
      allow(FileUtils).to receive(:rm_rf)

      expect { described_class.remove(repository) }.not_to raise_error
    end

    it 'raises an error when removal fails' do
      allow(repository).to receive(:path).and_return('/path/to/repo')
      allow(repository).to receive(:exists_locally?).and_return(true)
      allow(FileUtils).to receive(:rm_rf)

      expect do
        described_class.remove(repository)
      end.to raise_error(Repomate::Infra::Git::Operations::Error, 'Failed to remove repository')
    end
  end
end
