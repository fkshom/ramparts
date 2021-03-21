require 'ipaddr'
require 'yaml'

module RuleOperatorModule
  def resolve_host_object(hostnames)
    @repository.resolve_host(hostnames)
  end

  def resolve_port_object(portnames, protocol: nil, type:)
    @repository.resolve_port(portnames, protocol: protocol, type: type)
  end

  def aggregate_rules(by: [:dstport, :protocol])
    return @repository.rules.each_with_object([]) do |rule, acc|
      if ev = acc.detect{|ev| by.all?{|t| ev[t] == rule[t] } }
        ev.merge!( rule.merge(
          src: [ev[:src], rule[:src]].flatten.uniq,
          dst: [ev[:dst], rule[:dst]].flatten.uniq,
          srcport: [rule[:srcport], ev[:srcport]].flatten.uniq,
          dstport: [rule[:dstport], ev[:dstport]].flatten.uniq,
          protocol: [rule[:protocol], ev[:protocol]].flatten.uniq,
          action: rule[:action],
          ) )
      else
        acc << rule.dup
      end
    end
  end

  def flatten_rule(rule, order: [:src, :dst, :srcport, :dstport, :protocol, :action])
    def combine_arrays(*arrays)
      if arrays.empty?
        yield
      else
        first, *rest = arrays
        first.map do |x|
          combine_arrays(*rest) {|*args| yield x, *args }
        end.flatten
          #.flatten(1)
      end
    end
    result = []
    name = rule[:name]
    src = resolve_host_object(rule[:src])
    dst = resolve_host_object(rule[:dst])
    srcport = resolve_port_object(rule[:srcport], type: :src)
    dstport, protocol = resolve_port_object(rule[:dstport], protocol: rule[:protocol], type: :dst)
    src = [src].flatten()
    dst = [dst].flatten()
    srcport = [srcport].flatten()
    dstport = [dstport].flatten()

    combine_arrays(src, dst, srcport, dstport){|s, d, sp, dp, idx|
      result << {
        name: "#{name}",
        src: s, dst: d,
        srcport: sp, dstport: dp,
        protocol: protocol, action: rule[:action]
      }
    }
  end

end
module Ramparts
  module Routers; end
  class Routers::Junos; end
  class Routers::Junos::Rules
    include RuleOperatorModule
    def initialize(repository:)
      @repository = repository
      @rules = {}
    end

    def add_rule(filtername:, term:, rule:)
      @rules[filtername] ||= {}
      if @rules[filtername].key?(term)
        raise 'Rules already has key "#{term}"'
      end
      @rules[filtername][term] = rule
    end

    def to_h
      @rules
    end

    def to_a
      result = []
      @rules.each do |filtername, value1|
        value1.each do |termname, obj|
          src = resolve_host_object(obj[:src])
          [src].flatten().each do |e|
            result << "set firewall filter #{filtername} term #{termname} source-address #{e}"
          end

          dst = resolve_host_object(obj[:dst])
          [dst].flatten().each do |e|
            result << "set firewall filter #{filtername} term #{termname} destination-address #{e}"
          end

          srcport = resolve_port_object(obj[:srcport], type: :src)
          [srcport].flatten().each do |e|
            result << "set firewall filter #{filtername} term #{termname} source-port #{e}"
          end

          dstport, protocol = resolve_port_object(obj[:dstport], protocol: obj[:protocol], type: :dst)
          [dstport].flatten().each do |e|
            result << "set firewall filter #{filtername} term #{termname} destination-port #{e}"
          end
          result << "set firewall filter #{filtername} term #{termname} protocol #{protocol}"
          action = obj[:action]
          result << "set firewall filter #{filtername} term #{termname} #{action}"
        end
      end
      return result
    end

    def to_s
      to_a.join("\n")
    end
  end

  class Routers::Junos
    include RuleOperatorModule

    def initialize()
      @interfaces = []
      @repository = nil
    end

    def assign_interface(interfacename:, filtername:, direction:, address:)
      @interfaces << {
        interfacename: interfacename,
        filtername: filtername,
        direction: direction,
        address: address,
      }
    end

    def set_repository(func)
      @repository = func
    end
  end

  class Routers::Router1 < Routers::Junos
    def create_router_rules
      # 自機のinterfaceにinするルールを抽出する
      result_rules = Ramparts::Routers::Junos::Rules.new(repository: @repository)

      @repository.rules.each do |p_rule|
        @interfaces.each do |interface|
          rule = Marshal.load(Marshal.dump(p_rule))
          src = rule[:src].select{|s| 
            ho = Host.new(s, @repository)
            IPAddr.new(interface[:address]).include?(IPAddr.new(ho.address))
          }
          filtername = interface[:filtername]
          term = rule[:name]
          rule = rule.tap{|r| r.delete(:name); r}.merge(src: src)
          result_rules.add_rule(filtername: filtername, term: term, rule: rule)
        end
      end

      result_rules
    end     
  end

  class Routers::VDSTF; end
  class Routers::VDSTF::Rules
    include RuleOperatorModule
    def initialize(repository:)
      @repository = repository
      @rules = {}
    end

    def add_rule(dcname:, pgname:, rule:)
      @rules[dcname] ||= {}
      @rules[dcname][pgname] ||= []
      @rules[dcname][pgname] << rule
    end

    def to_h
      @rules
    end

    def to_yaml
      result = {}
      def combine_arrays(*arrays)
        if arrays.empty?
          yield
        else
          first, *rest = arrays
          first.map do |x|
            combine_arrays(*rest) {|*args| yield x, *args }
          end.flatten
            #.flatten(1)
        end
      end

      @rules.each do |dcname, value1|
        result[dcname] ||= {}
        value1.each do |portgroupname, objs|
          result[dcname][portgroupname] ||= []
          objs.each do |obj|
            src = resolve_host_object(obj[:src])
            dst = resolve_host_object(obj[:dst])
            srcport = resolve_port_object(obj[:srcport], type: :src)
            dstport, protocol = resolve_port_object(obj[:dstport], protocol: obj[:protocol], type: :dst)
            src = [src].flatten()
            dst = [dst].flatten()
            srcport = [srcport].flatten()
            dstport = [dstport].flatten()

            # src.product(dst, srcport, dstport){|s, d, sp, dp|
            combine_arrays(src, dst, srcport, dstport){|s, d, sp, dp|
              result[dcname][portgroupname] << {
                desc: "TERM1", 
                src: s, dst: d,
                srcport: sp, dstport: dp,
                protocol: protocol, action: obj[:action]
              }
            }
            
          end
        end
      end
      return result
    end

    def to_s
      to_yaml
    end
  end
  
  class Routers::VDSTF
    include RuleOperatorModule

    def initialize()
      @portgroups = []
      @rules = []
      @repository = nil
    end

    def assign_portgroup(dcname:, portgroupname:, address:)
      @portgroups << {
        dcname: dcname,
        portgroupname: portgroupname,
        address: address
      }
    end

    def set_repository(func)
      @repository = func
    end
  end

  class Routers::VDSTF1 < Routers::VDSTF
    def create_router_rules
      # 自PortGroupのアドレスがdestinationであるルールを抽出する
      result_rules = Ramparts::Routers::VDSTF::Rules.new(repository: @repository)

      @repository.rules.each do |p_rule|
        @portgroups.each do |portgroup|
          rule = Marshal.load(Marshal.dump(p_rule))
          rule[:src] = rule[:src].select{|s| 
            ho = Host.new(s, @repository)
            IPAddr.new(portgroup[:address]).include?(IPAddr.new(ho.address))
          }
          dcname = portgroup[:dcname]
          pgname = portgroup[:portgroupname]
          rule = {
            desc: rule[:name],
            src: [rule[:src]].flatten(),
            dst: [rule[:dst]].flatten(),
            srcport: [rule[:srcport]].flatten(),
            dstport: rule[:dstport],
            protocol: rule[:protocol],
            action: rule[:action],
          }
          result_rules.add_rule(dcname: dcname, pgname: pgname, rule: rule)
        end
      end
      return result_rules
    end

  end
end
