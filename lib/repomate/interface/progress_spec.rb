# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../domain/result'
require_relative './progress'

describe Repomate::Interface::Progress do
  let(:result) { Repomate::Domain::Result.success('repo1 updated') }

  describe '.build' do
    it 'draws bars when the output is a terminal' do
      output = StringIO.new
      allow(output).to receive(:tty?).and_return(true)

      expect(described_class.build(%w[repo1], output: output)).to be_a(described_class)
    end

    it 'falls back to plain lines when the output is not a terminal' do
      expect(described_class.build(%w[repo1], output: StringIO.new)).to be_a(described_class::Plain)
    end
  end

  describe described_class::Plain do
    it 'prints a single line per finished repository' do
      output = StringIO.new
      progress = described_class.new(output)

      progress.begin('repo1')
      progress.update('repo1', 0.5, 'pulling')
      progress.finish('repo1', result)

      expect(output.string).to eq("repo1 updated\n")
    end
  end

  describe '#finish' do
    let(:columns) { 80 }
    let(:output) do
      StringIO.new.tap do |io|
        io.define_singleton_method(:winsize) { [24, 80] }
        allow(io).to receive(:tty?).and_return(true)
        allow(io).to receive(:winsize) { [24, columns] }
      end
    end

    subject { described_class.new(%w[repo1 repo2], output) }

    it 'prints the result above the board and keeps the remaining bars' do
      subject.begin('repo1')
      subject.begin('repo2')
      subject.send(:tick)
      subject.finish('repo1', result)

      expect(output.string).to include('repo1 updated')
      expect(output.string.lines.last).to include('repo2')
    end

    context 'in a narrow terminal' do
      let(:columns) { 30 }

      it 'never draws a line wider than the terminal' do
        subject.begin('repo1')
        subject.update('repo1', 0.5, 'pulling')
        subject.send(:tick)

        visible = output.string.lines.last.gsub(/\e\[[0-9;?]*[a-zA-Z]/, '').chomp

        expect(visible.length).to be <= 29
      end
    end
  end
end
