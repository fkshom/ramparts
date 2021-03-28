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
end
