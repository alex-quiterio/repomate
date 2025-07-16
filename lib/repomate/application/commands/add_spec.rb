# frozen_string_literal: true

require 'spec_helper'
require_relative './base'
require_relative './add'

describe Repomate::Application::Commands::Add do
  let(:config) { instance_double('Config', repo_url: repo_url, code_path: '/test/code') }
  let(:store) { instance_double('Store') }
  let(:command) { described_class.new(config: config, store: store) }
  let(:repository) { instance_double('Repository') }
  let(:result) { instance_double('Result', message: 'Test message') }

  describe '#execute' do
    context 'when repo_url is not provided' do
      let(:repo_url) { nil }

      it 'prints an error message' do
        expect { command.execute }.to output(
          "\e[31mRepository URL is required. Use -l or --repo-url.\e[0m\n"
        ).to_stdout
      end
    end

    context 'when repo_url is provided' do
      let(:repo_url) { 'git@github.com:user/repo.git' }

      before do
        allow(Repomate::Domain::Repository).to receive(:from_url)
          .with(repo_url, '/test/code')
          .and_return(repository)
        allow(store).to receive(:add).with(repository).and_return(result)
      end

      it 'creates a repository from the URL' do
        expect(Repomate::Domain::Repository).to receive(:from_url)
          .with(repo_url, '/test/code')
          .and_return(repository)

        command.execute
      end

      it 'adds the repository to the store' do
        expect(store).to receive(:add).with(repository).and_return(result)
        command.execute
      end

      it 'prints the result message' do
        expect { command.execute }.to output("Test message\n").to_stdout
      end

      context 'when git operation fails' do
        let(:git_error) { Repomate::Infra::Git::Operations::Error.new('Git failed') }

        before do
          allow(store).to receive(:add).and_raise(git_error)
        end

        it 'prints an error message' do
          expect { command.execute }.to output(
            "\e[31mError synchronizing the repository locally: Git failed\e[0m\n"
          ).to_stdout
        end
      end
    end
  end
end
