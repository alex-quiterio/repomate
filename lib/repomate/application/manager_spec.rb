# frozen_string_literal: true

require 'spec_helper'
require 'repomate'

describe Repomate::Application::Manager do
  let(:config) do
    instance_double(
      Repomate::Config::Configuration,
      command: 'sync',
      config_file_path: '/tmp/test_config',
      code_path: '/tmp/test_code'
    )
  end

  let(:store) do
    instance_double(Repomate::Infra::Persistence::RepositoryStore)
  end

  let(:command) do
    instance_double(Repomate::Application::Commands::Sync)
  end

  subject { described_class.new(config) }

  before do
    allow(Repomate::Infra::Persistence::RepositoryStore).to receive(:new)
      .with(config_file_path: '/tmp/test_config', code_path: '/tmp/test_code')
      .and_return(store)
  end

  describe '#initialize' do
    it 'creates a repository store with config parameters' do
      expect(Repomate::Infra::Persistence::RepositoryStore).to receive(:new)
        .with(config_file_path: '/tmp/test_config', code_path: '/tmp/test_code')
        .and_return(store)

      described_class.new(config)
    end
  end

  describe '#run' do
    before do
      allow(Repomate::Application::CommandFactory).to receive(:create)
        .with(name: 'sync', config: config, store: store)
        .and_return(command)
    end

    context 'when command executes successfully' do
      it 'creates and executes the command' do
        expect(command).to receive(:execute)

        subject.run
      end
    end

    context 'when command factory raises UnknownCommandError' do
      let(:error_message) { 'Unknown command: invalid' }

      before do
        allow(Repomate::Application::CommandFactory).to receive(:create)
          .and_raise(Repomate::Application::UnknownCommandError, error_message)
      end

      it 'prints the error message and exits with code 1' do
        expect do
          expect { subject.run }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        end.to output("#{error_message}\n").to_stdout
      end
    end

    context 'with different command types' do
      Repomate::Application::CommandFactory::COMMANDS.each do |command_name, command_class|
        it "handles #{command_name} command" do
          allow(config).to receive(:command).and_return(command_name.to_s)

          command_instance = instance_double(command_class)

          expect(Repomate::Application::CommandFactory).to receive(:create)
            .with(name: command_name.to_s, config: config, store: store)
            .and_return(command_instance)

          expect(command_instance).to receive(:execute)

          subject.run
        end
      end
    end
  end
end
