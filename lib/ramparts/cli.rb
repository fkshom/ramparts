require 'ramparts'
require 'thor'
require 'csv'
require 'pp'

module Ramparts
  class CLI < Thor
    desc "format", "do format"
    option :juniper, type: :boolean, aliases: '-j', default: true, desc: 'files is juniper config'
    option :vds, type: :boolean, aliases: '-v', default: false, desc: 'files is vds config'
    def format(*files)
      files.each{|filename|
        loader = Ramparts::RepositoryFileLoader.new(filename)
        loader.save(filename, format: true)
      }
    end

    desc "generate", "do generate"
    def generate()
      repository = Ramparts::Repository.new()
      repository.load_dir('sample_data2')

      l_interfaces = YAML.load_file("sample_data/interfaces.yml")
      router = Ramparts::Routers::Router1.new(repository)

      (l_interfaces['router1'] || []).each do |interface|
        router.assign_interface(interfacename: interface['interfacename'], filtername: interface['filtername'],
          direction: interface['direction'], address: interface['address'])
      end

      rules = router.create_rules()
      pp rules.class  # Ramprts::Routers::Base::Junos::Rules
      pp rules.to_h
      puts rules.to_s

      router = Ramparts::Routers::Vds1.new(repository)

      (l_interfaces['vds1'] || []).each do |interface|
        router.assign_portgroup(dcname: interface['dcname'], portgroupname: interface['pgname'],
          address: interface['address'])
      end

      rules = router.create_rules()
      pp rules.class
      pp rules.to_h

      router = Ramparts::Routers::Vds1a.new(repository, name='vds1')
      (l_interfaces['vds1'] || []).each do |interface|
        router.assign_portgroup(dcname: interface['dcname'], portgroupname: interface['pgname'],
          address: interface['address'])
      end
      rules = router.create_rules()
      pp rules.to_h
    end
  end
end
