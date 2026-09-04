# frozen_string_literal: true

require 'spec_helper'
require_relative './repository'

describe Repomate::Domain::Repository do
  let(:code_path) { '/tmp/repos' }
  let(:repo_name) { 'user/project' }
  let(:repository) { described_class.new(name: repo_name, code_path: code_path) }

  describe '.from_url' do
    it 'creates a repository from a git URL' do
      url = 'git@github.com:user/project.git'
      repo = described_class.from_url(url, code_path)
      expect(repo.name).to eq('user/project')
      expect(repo.path).to eq('/tmp/repos/user/project')
    end
  end

  describe '#initialize' do
    it 'sets the appropriate attributes' do
      expect(repository.name).to eq(repo_name)
      expect(repository.path).to eq('/tmp/repos/user/project')
    end
  end

  describe '#exists_locally?' do
    it 'returns true when the directory exists' do
      allow(Dir).to receive(:exist?).with('/tmp/repos/user/project').and_return(true)
      expect(repository.exists_locally?).to be(true)
    end

    it 'returns false when the directory does not exist' do
      allow(Dir).to receive(:exist?).with('/tmp/repos/user/project').and_return(false)
      expect(repository.exists_locally?).to be(false)
    end
  end

  describe '#url' do
    it 'returns the properly formatted git URL' do
      expect(repository.url).to eq('git@github.com:user/project.git')
    end
  end

  describe '#==' do
    it 'returns true when repositories have the same URL' do
      other_repo = described_class.new(name: repo_name, code_path: code_path)
      expect(repository == other_repo).to be(true)
    end

    it 'returns false when repositories have different URLs' do
      other_repo = described_class.new(name: 'other/project', code_path: code_path)
      expect(repository == other_repo).to be(false)
    end

    it 'returns false when compared to a non-repository object' do
      expect(repository == 'not-a-repo').to be(false)
    end
  end

  describe '#valid?' do
    it 'returns true when URL is valid' do
      expect(repository.valid?).to be(true)
    end

    it 'returns false when repo name does not include a forward slash' do
      invalid_repo = described_class.new(name: 'invalid-name', code_path: code_path)
      expect(invalid_repo.valid?).to be(false)
    end
  end
end
