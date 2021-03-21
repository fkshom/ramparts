require 'ramparts'
require 'thor'

module Ramparts
  class CLI < Thor
    desc "parse", "do parse"
    option :juniper, type: :boolean, aliases: '-j', default: :true, desc: 'files is juniper config'
    option :vds, type: :boolean, aliases: '-v', default: :false, desc: 'files is vds config'
    def parse(*files)
      p options[:type]
      p files
    end
  end
end