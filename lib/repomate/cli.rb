module Repomate
  class CLI
    def self.start
      config = Config.new
      manager = Manager.new(config)
      manager.run
    end
  end
end
