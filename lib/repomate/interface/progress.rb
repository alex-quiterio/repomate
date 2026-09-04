# frozen_string_literal: true

require 'io/console'

module Repomate
  module Interface
    # A live progress board: one bar per repository currently being synced,
    # redrawn in place while the workers run. Finished repositories are printed
    # above the board so the log keeps scrolling normally.
    class Progress
      BAR_WIDTH = 20
      NAME_WIDTH = 28
      FRAME_SECONDS = 0.08
      SPINNER = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze

      # Plain, one-line-per-repository output for pipes, CI logs and specs,
      # where cursor movement would only produce noise.
      class Plain
        def initialize(output)
          @output = output
          @lock = Mutex.new
        end

        def start; end
        def stop; end
        def begin(name); end
        def update(name, fraction, label); end

        def finish(_name, result)
          @lock.synchronize { @output.puts(result.message) }
        end
      end

      def self.build(names, output: $stdout)
        return Plain.new(output) unless output.tty?

        new(names, output)
      end

      def initialize(names, output)
        @output = output
        @width = [names.map(&:length).max.to_i, NAME_WIDTH].min
        @active = {}
        @lock = Mutex.new
        @drawn = 0
        @frame = 0
      end

      def start
        @running = true
        @output.print("\e[?25l")
        @thread = Thread.new do
          while @running
            tick
            sleep(FRAME_SECONDS)
          end
        end
      end

      def stop
        @running = false
        @thread&.join
        @lock.synchronize do
          erase
          @output.print("\e[?25h")
          @output.flush
        end
      end

      def begin(name)
        @lock.synchronize { @active[name] = [0.0, 'starting'] }
      end

      def update(name, fraction, label)
        @lock.synchronize { @active[name] = [fraction, label] }
      end

      def finish(name, result)
        @lock.synchronize do
          @active.delete(name)
          erase
          @output.puts(result.message)
          draw
        end
      end

      private

      def tick
        @lock.synchronize do
          @frame += 1
          erase
          draw
        end
      end

      def erase
        return if @drawn.zero?

        @output.print("\e[#{@drawn}A\e[J")
        @drawn = 0
      end

      def draw
        lines = @active.map { |name, (fraction, label)| line_for(name, fraction, label) }
        @output.print(lines.map { |line| "#{line}\n" }.join)
        @output.flush
        @drawn = lines.length
      end

      def line_for(name, fraction, label)
        spinner = SPINNER[@frame % SPINNER.length]
        percent = (fraction * 100).round.clamp(0, 100)

        truncate("\e[36m#{spinner}\e[0m #{name.slice(0, @width).ljust(@width)} " \
                 "#{bar(fraction)} \e[2m#{percent.to_s.rjust(3)}% #{label}\e[0m")
      end

      def bar(fraction)
        filled = (fraction.clamp(0.0, 1.0) * BAR_WIDTH).round

        "\e[36m▕#{'█' * filled}#{'░' * (BAR_WIDTH - filled)}▏\e[0m"
      end

      # Wrapped lines would break the cursor arithmetic, so keep every line
      # inside the terminal width (escape sequences take up no columns).
      def truncate(line)
        columns = terminal_columns
        visible = 0

        line.gsub(/\e\[[0-9;?]*[a-zA-Z]|./) do |token|
          next token if token.start_with?("\e")
          next '' if visible >= columns

          visible += 1
          token
        end
      end

      def terminal_columns
        @output.winsize.last - 1
      rescue StandardError
        79
      end
    end
  end
end
