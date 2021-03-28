# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

require_relative "ramparts/version"
require_relative "ramparts/logger"
require_relative "ramparts/repository"
require_relative "ramparts/routers"

module Ramparts::Routers::Base; end
require_relative "ramparts/routers/base/junos"
require_relative "ramparts/routers/base/vds"
require_relative "ramparts/routers/router1"
require_relative "ramparts/routers/vds1"

module Ramparts
  class Error < StandardError; end
  class << self
    def logger
      @logger ||= Filtergen::Logger.new.create
    end

    def log_path=(logdev)
      logger.reopen(logdev)
    end

    def log_level=(value)
      logger.level = value1
    end

    def log_level
      %i[DEBUG INFO WARN ERROR FATAL UNKNOWN][logger.level]
    end
  end
end
