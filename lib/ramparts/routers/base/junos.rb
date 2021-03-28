
module Ramparts::Routers::Base
  class Junos
    class Rules
      include RuleOperatorModule
      def initialize()
        @rules = {}
      end

      def add_rule(filtername:, term:, rule:)
        @rules[filtername] ||= {}
        raise 'Rules already has key "#{term}"' if @rules[filtername].key?(term)
        @rules[filtername][term] = rule
        self
      end

      def to_h
        @rules
      end

      def to_a
        result = []
        @rules.each do |filtername, terms|
          terms.each do |termname, obj|
            [obj[:src]].flatten.each do |e|
              result << "set firewall filter #{filtername} term #{termname} source-address #{e}" unless e.nil?
            end
            [obj[:dst]].flatten.each do |e|
              result << "set firewall filter #{filtername} term #{termname} destination-address #{e}" unless e.nil?
            end
            [obj[:srcport]].flatten.each do |e|
              result << "set firewall filter #{filtername} term #{termname} source-port #{e}" unless e.nil?
            end
            [obj[:dstport]].flatten.each do |e|
              result << "set firewall filter #{filtername} term #{termname} destination-port #{e}" unless e.nil?
            end
            result << "set firewall filter #{filtername} term #{termname} protocol #{obj[:protocol]}" unless obj[:protocol].nil?
            result << "set firewall filter #{filtername} term #{termname} #{obj[:action]}"
          end
        end
        result
      end

      def to_s
        to_a.join("\n")
      end
    end

    include RuleOperatorModule
    attr_accessor :rules, :interfaces

    def initialize()
      @interfaces = []
      @rules = Rules.new()
    end

    def assign_interface(interfacename:, filtername:, direction:, address:)
      @interfaces << {
        interfacename: interfacename,
        filtername: filtername,
        direction: direction,
        address: address,
      }
    end

    def add_rule(filtername:, term:, src:, dst:, srcport:, dstport:, protocol:, action:)
      @rules.add_rule(filtername: filtername, term: term,
        rule: {
          src: src, dst: dst, srcport: srcport, dstport: dstport, protocol: protocol, action: action,
        }
      )
    end
  end
end