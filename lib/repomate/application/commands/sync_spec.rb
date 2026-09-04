# frozen_string_literal: true

require 'spec_helper'
require_relative '../../domain/result'
require_relative '../../infra/git/operations'
require_relative '../../interface/progress'
require_relative './base'
require_relative './sync'

describe Repomate::Application::Commands::Sync do
  let(:config) { instance_double('Configuration', pattern: nil, jobs: 4) }
  let(:store) { instance_double('RepositoryStore') }
  let(:repository1) { instance_double('Repository', name: 'repo1', url: 'git@github.com:user/repo1.git') }
  let(:repository2) { instance_double('Repository', name: 'repo2', url: 'git@github.com:alex-quiterio/repo2.git') }
  let(:repositories) { [repository1, repository2] }
  let(:success) { Repomate::Domain::Result.success('synced') }
  let(:progress) { instance_double(Repomate::Interface::Progress::Plain, start: nil, stop: nil, begin: nil, finish: nil) }

  subject { described_class.new(config: config, store: store) }

  describe '#execute' do
    before do
      allow(store).to receive(:all).and_return(repositories)
      allow(subject).to receive(:puts)
      allow(subject).to receive(:progress_for).and_return(progress)
      allow(subject).to receive(:sync_repository).and_return(success)
    end

    context 'when no repositories are configured' do
      before do
        allow(store).to receive(:all).and_return([])
      end

      it 'displays a message and returns' do
        expect(subject).to receive(:puts).with('No repositories to sync')
        subject.execute
      end
    end

    context 'when repositories are configured' do
      context 'without a pattern' do
        it 'syncs all repositories' do
          expect(subject).to receive(:puts).with("\e[34mSyncing 2 repositories...\e[0m")
          expect(subject).to receive(:sync_repository).with(repository1).and_return(success)
          expect(subject).to receive(:sync_repository).with(repository2).and_return(success)
          expect(subject).to receive(:puts).with("\e[34mSync complete ✨\e[0m")

          subject.execute
        end

        it 'never starts more workers than there are repositories' do
          expect(subject).to receive(:workers).with(2).and_call_original

          subject.execute
        end

        context 'with fewer jobs than repositories' do
          let(:config) { instance_double('Configuration', pattern: nil, jobs: 1) }

          it 'uses the configured number of workers' do
            expect(subject).to receive(:workers).with(1).and_call_original

            subject.execute
          end
        end
      end

      context 'with a pattern' do
        let(:config) { instance_double('Configuration', pattern: 'alex-quiterio', jobs: 4) }

        it 'syncs only repositories matching the pattern' do
          expect(subject).to receive(:puts).with("\e[34mSyncing 1 repositories...\e[0m")
          expect(subject).to receive(:sync_repository).with(repository2).and_return(success)
          expect(subject).not_to receive(:sync_repository).with(repository1)
          expect(subject).to receive(:puts).with("\e[34mSync complete ✨\e[0m")

          subject.execute
        end

        context 'when no repositories match the pattern' do
          let(:config) { instance_double('Configuration', pattern: 'nonexistent', jobs: 4) }

          it 'displays a message and returns' do
            expect(subject).to receive(:puts).with('No repositories to sync')
            expect(subject).not_to receive(:sync_repository)

            subject.execute
          end
        end
      end

      context 'when sync fails for a repository' do
        let(:failure) { Repomate::Domain::Result.failure('Error syncing repo1') }

        before do
          allow(subject).to receive(:sync_repository).with(repository1).and_return(failure)
          allow(subject).to receive(:sync_repository).with(repository2).and_return(success)
        end

        it 'reports the failure and still syncs the other repositories' do
          expect(progress).to receive(:finish).with('repo1', failure)
          expect(subject).to receive(:sync_repository).with(repository2).and_return(success)
          expect(subject).to receive(:puts).with("\e[33mSync complete with 1 failed repositories\e[0m")

          subject.execute
        end
      end
    end
  end

  describe '#optionally_filter_repositories_by_pattern' do
    context 'without a pattern' do
      it 'returns all repositories' do
        result = subject.send(:optionally_filter_repositories_by_pattern, repositories)
        expect(result).to eq(repositories)
      end
    end

    context 'with a pattern' do
      let(:config) { instance_double('Configuration', pattern: 'alex-quiterio', jobs: 4) }

      it 'returns only repositories matching the pattern' do
        result = subject.send(:optionally_filter_repositories_by_pattern, repositories)
        expect(result).to eq([repository2])
      end

      context 'when no repositories match' do
        let(:config) { instance_double('Configuration', pattern: 'nonexistent', jobs: 4) }

        it 'returns an empty array' do
          result = subject.send(:optionally_filter_repositories_by_pattern, repositories)
          expect(result).to eq([])
        end
      end
    end
  end

  describe '#sync_repository' do
    let(:git_operations) { class_double('Repomate::Infra::Git::Operations') }

    before do
      stub_const('Repomate::Infra::Git::Operations', git_operations)
      stub_const('Repomate::Infra::Git::Operations::Error', Class.new(StandardError))
      allow(subject).to receive(:puts)
    end

    it 'forwards progress updates from the git operation' do
      allow(repository1).to receive(:exists_locally?).and_return(true)
      allow(git_operations).to receive(:update) { |_repository, &block| block.call(0.5, 'pulling') }

      reported = []
      subject.send(:sync_repository, repository1) { |fraction, label| reported << [fraction, label] }

      expect(reported).to eq([[0.5, 'pulling']])
    end

    context 'when repository exists locally' do
      before do
        allow(repository1).to receive(:exists_locally?).and_return(true)
      end

      it 'updates the repository' do
        expect(git_operations).to receive(:update).with(repository1).and_return(true)

        result = subject.send(:sync_repository, repository1)

        expect(result).to be_success
        expect(result.message).to include('repo1 updated')
      end

      it 'reports when there was nothing to pull' do
        expect(git_operations).to receive(:update).with(repository1).and_return(false)

        result = subject.send(:sync_repository, repository1)

        expect(result).to be_success
        expect(result.message).to include('repo1 no changes to pull')
      end

      it 'returns a failure when the update raises' do
        allow(git_operations).to receive(:update)
          .and_raise(Repomate::Infra::Git::Operations::Error.new('Failed to sync'))

        result = subject.send(:sync_repository, repository1)

        expect(result).not_to be_success
        expect(result.message).to include('repo1: Failed to sync')
      end
    end

    context 'when repository does not exist locally' do
      before do
        allow(repository1).to receive(:exists_locally?).and_return(false)
      end

      it 'clones the repository' do
        expect(git_operations).to receive(:clone).with(repository1)

        result = subject.send(:sync_repository, repository1)

        expect(result).to be_success
        expect(result.message).to include('repo1 cloned')
      end
    end
  end
end
