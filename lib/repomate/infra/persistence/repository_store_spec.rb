# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'fileutils'
require_relative './repository_store'

describe Repomate::Infra::Persistence::RepositoryStore do # rubocop:disable Metrics/BlockLength
  let(:temp_file) { Tempfile.new('repos') }
  let(:config_file_path) { temp_file.path }
  let(:code_path) { config_file_path }
  let(:repository) { instance_double(Repomate::Domain::Repository, url: 'https://github.com/user/repo.git', name: 'repo', valid?: true) }

  subject { described_class.new(config_file_path: config_file_path, code_path: code_path) }

  after do
    temp_file.close
    temp_file.unlink
  end

  describe '#initialize' do
    context 'when config file does not exist' do
      before do
        temp_file.close
        temp_file.unlink
      end

      it 'creates the config file' do
        non_existent_config_file_path = Tempfile.new('repos').path

        allow(File).to receive(:exist?).with(non_existent_config_file_path).and_return(false)
        expect(FileUtils).to receive(:touch).with(non_existent_config_file_path)
        described_class.new(config_file_path: non_existent_config_file_path, code_path: code_path)
      end
    end
  end

  describe '#all' do
    context 'when config file is empty' do
      it 'returns an empty array' do
        expect(subject.all).to eq([])
      end
    end

    context 'when config file has URLs' do
      before do
        File.write(config_file_path, "https://github.com/user/repo1.git\nhttps://github.com/user/repo2.git\n")
      end

      it 'returns repositories for each URL' do
        repos = [
          instance_double(Repomate::Domain::Repository),
          instance_double(Repomate::Domain::Repository)
        ]

        expect(Repomate::Domain::Repository).to receive(:from_url).with('https://github.com/user/repo1.git',
                                                                        code_path).and_return(repos[0])
        expect(Repomate::Domain::Repository).to receive(:from_url).with('https://github.com/user/repo2.git',
                                                                        code_path).and_return(repos[1])

        expect(subject.all).to eq(repos)
      end
    end
  end

  describe '#add' do
    let(:repository) { instance_double(Repomate::Domain::Repository, url: 'https://github.com/user/repo.git', name: 'repo', valid?: true) }

    context 'when repository URL is invalid' do
      let(:invalid_repo) { instance_double(Repomate::Domain::Repository, valid?: false) }

      it 'returns failure result' do
        result = subject.add(invalid_repo)
        expect(result.success?).to be false
        expect(result.message).to eq('Invalid repository URL')
      end
    end

    context 'when repository already exists' do
      before do
        allow(subject).to receive(:contains?).with(repository).and_return(true)
      end

      it 'returns failure result' do
        result = subject.add(repository)
        expect(result.success?).to be false
        expect(result.message).to eq('Repository already exists')
      end
    end

    context 'when repository can be added' do
      before do
        allow(subject).to receive(:contains?).with(repository).and_return(false)
        allow(Repomate::Infra::Git::Operations).to receive(:clone).with(repository)
      end

      it 'adds the repository URL to the config file' do
        subject.add(repository)
        expect(File.read(config_file_path)).to include('https://github.com/user/repo.git')
      end

      it 'clones the repository' do
        expect(Repomate::Infra::Git::Operations).to receive(:clone).with(repository)
        subject.add(repository)
      end

      it 'returns success result' do
        result = subject.add(repository)
        expect(result.success?).to be true
        expect(result.message).to eq('repo added 📦')
      end
    end
  end

  describe '#remove' do
    context 'when repository does not exist' do
      before do
        allow(subject).to receive(:contains?).with(repository).and_return(false)
      end

      it 'returns failure result' do
        result = subject.remove(repository)
        expect(result.success?).to be false
        expect(result.message).to eq('Repository not found')
      end
    end

    context 'when repository exists' do
      let(:other_repo) { instance_double(Repomate::Domain::Repository, url: 'https://github.com/user/other.git') }

      before do
        allow(subject).to receive(:contains?).with(repository).and_return(true)
        allow(subject).to receive(:all).and_return([repository, other_repo])
        allow(Repomate::Infra::Git::Operations).to receive(:remove).with(repository)
      end

      it 'removes the repository from the config file' do
        subject.remove(repository)
        expect(File.read(config_file_path)).not_to include('https://github.com/user/repo.git')
        expect(File.read(config_file_path)).to include('https://github.com/user/other.git')
      end

      it 'removes the repository directory' do
        expect(Repomate::Infra::Git::Operations).to receive(:remove).with(repository)
        subject.remove(repository)
      end

      it 'returns success result' do
        result = subject.remove(repository)
        expect(result.success?).to be true
        expect(result.message).to eq('repo removed 🗑')
      end
    end
  end

  describe '#contains?' do
    it 'returns true when repository exists' do
      allow(subject).to receive(:all).and_return([repository])
      expect(subject.contains?(repository)).to be true
    end

    it 'returns false when repository does not exist' do
      allow(subject).to receive(:all).and_return([])
      expect(subject.contains?(repository)).to be false
    end
  end
end
