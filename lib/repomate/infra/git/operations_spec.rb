# frozen_string_literal: true

require 'fileutils'
require 'spec_helper'
require_relative './operations'

describe Repomate::Infra::Git::Operations do
  let(:repository) { double('repository') }

  describe '.update' do
    before do
      allow(repository).to receive(:path).and_return('/path/to/repo')
      allow(described_class).to receive(:capture).and_return('main')
    end

    it 'updates the repository successfully' do
      allow(described_class).to receive(:system).and_return(true)

      expect(described_class.update(repository)).to eq(true)
    end

    it 'runs every command against the repository path instead of changing directory' do
      allow(described_class).to receive(:system).and_return(true)
      expect(Dir).not_to receive(:chdir)

      described_class.update(repository)

      expect(described_class).to have_received(:system)
        .with(anything, hash_including(chdir: '/path/to/repo')).at_least(:once)
    end

    it 'returns false when there is nothing to pull' do
      allow(described_class).to receive(:system).and_return(false)

      expect(described_class.update(repository)).to eq(false)
    end

    it 'reports progress from the percentages git prints' do
      allow(described_class).to receive(:system).and_return(true)
      allow(described_class).to receive(:stream) do |_path, _command, &on_line|
        on_line.call('Receiving objects:  50% (5/10)')
        true
      end

      reported = []
      described_class.update(repository) { |fraction, label| reported << [fraction.round(2), label] }

      expect(reported).to include([0.2, 'fetching'], [0.68, 'pulling'])
      expect(reported.last).to eq([1.0, 'updated'])
    end

    it 'raises an error when a command blows up' do
      allow(described_class).to receive(:system).and_raise(StandardError.new('boom'))

      expect do
        described_class.update(repository)
      end.to raise_error(Repomate::Infra::Git::Operations::Error, 'Failed to update repository: boom')
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
