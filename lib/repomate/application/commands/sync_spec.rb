# frozen_string_literal: true

require 'spec_helper'
require_relative './base'
require_relative './sync'

describe Repomate::Application::Commands::Sync do
  let(:config) { instance_double('Configuration', pattern: nil) }
  let(:store) { instance_double('RepositoryStore') }
  let(:repository1) { instance_double('Repository', name: 'repo1', url: 'git@github.com:user/repo1.git') }
  let(:repository2) { instance_double('Repository', name: 'repo2', url: 'git@github.com:alex-quiterio/repo2.git') }
  let(:repositories) { [repository1, repository2] }

  subject { described_class.new(config: config, store: store) }

  describe '#execute' do
    before do
      allow(store).to receive(:all).and_return(repositories)
      allow(subject).to receive(:puts)
      allow(subject).to receive(:sync_repository)
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
          expect(subject).to receive(:sync_repository).with(repository1)
          expect(subject).to receive(:sync_repository).with(repository2)
          expect(subject).to receive(:puts).with("\e[34mSync complete ✨\e[0m")

          subject.execute
        end
      end

      context 'with a pattern' do
        let(:config) { instance_double('Configuration', pattern: 'alex-quiterio') }

        it 'syncs only repositories matching the pattern' do
          expect(subject).to receive(:puts).with("\e[34mSyncing 1 repositories...\e[0m")
          expect(subject).to receive(:sync_repository).with(repository2)
          expect(subject).not_to receive(:sync_repository).with(repository1)
          expect(subject).to receive(:puts).with("\e[34mSync complete ✨\e[0m")

          subject.execute
        end

        context 'when no repositories match the pattern' do
          let(:config) { instance_double('Configuration', pattern: 'nonexistent') }

          it 'displays a message and returns' do
            expect(subject).to receive(:puts).with('No repositories to sync')
            expect(subject).not_to receive(:sync_repository)

            subject.execute
          end
        end
      end

      context 'when sync fails for a repository' do
        before do
          allow(subject).to receive(:sync_repository).with(repository1)
                                                     .and_raise(Repomate::Infra::Git::Operations::Error.new('Failed to sync'))
          allow(subject).to receive(:sync_repository).with(repository2)
        end

        it 'continues syncing other repositories and shows error message' do
          expect(subject).to receive(:puts).with('Error syncing git@github.com:user/repo1.git: Failed to sync')
          expect(subject).to receive(:sync_repository).with(repository2)

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
      let(:config) { instance_double('Configuration', pattern: 'alex-quiterio') }

      it 'returns only repositories matching the pattern' do
        result = subject.send(:optionally_filter_repositories_by_pattern, repositories)
        expect(result).to eq([repository2])
      end

      context 'when no repositories match' do
        let(:config) { instance_double('Configuration', pattern: 'nonexistent') }

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
      allow(subject).to receive(:puts)
    end

    context 'when repository exists locally' do
      before do
        allow(repository1).to receive(:exists_locally?).and_return(true)
      end

      it 'updates the repository' do
        expect(subject).to receive(:puts).with('♲ repo1...')
        expect(git_operations).to receive(:update).with(repository1)

        subject.send(:sync_repository, repository1)
      end
    end

    context 'when repository does not exist locally' do
      before do
        allow(repository1).to receive(:exists_locally?).and_return(false)
      end

      it 'clones the repository' do
        expect(git_operations).to receive(:clone).with(repository1)

        subject.send(:sync_repository, repository1)
      end
    end
  end
end
