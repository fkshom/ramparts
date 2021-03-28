
module Ramparts::Routers::Base
  class Vds
    class Rules
      include RuleOperatorModule
      def initialize()
        @rules = {}
      end

      def add_rule(dcname:, pgname:, rule:)
        @rules[dcname] ||= {}
        @rules[dcname][pgname] ||= []
        @rules[dcname][pgname] << rule
      end

      def to_h
        result = {}
        @rules.each do |dcname, pgnames|
          result[dcname] ||= {}
          pgnames.each do |pgname, objs|
            result[dcname][pgname] ||= []
            objs.each do |obj|
              src = obj[:src].nil? ? 'any' : obj[:src]
              dst = obj[:dst].nil? ? 'any' : obj[:dst]
              srcport = obj[:srcport].nil? ? 'any' : obj[:srcport]
              dstport = obj[:dstport].nil? ? 'any' : obj[:dstport]
              protocol = obj[:protocol].nil? ? 'any' : obj[:protocol]
              result[dcname][pgname] << {
                description: obj[:description],
                src: src, dst: dst,
                srcport: srcport, dstport: dstport,
                protocol: protocol, action: obj[:action]
              }
            end
          end
        end
        result
      end

      # def to_h_old
      #   def combine_arrays(*arrays)
      #     if arrays.empty?
      #       yield
      #     else
      #       first, *rest = arrays
      #       first.map do |x|
      #         combine_arrays(*rest) {|*args| yield x, *args }
      #       end.flatten
      #     end
      #   end
      #   result = {}

      #   @rules.each do |dcname, pgnames|
      #     result[dcname] ||= {}
      #     pgnames.each do |pgname, objs|
      #       result[dcname][pgname] ||= []
      #       objs.each do |obj|
      #         src = obj[:src]
      #         dst = obj[:dst]
      #         srcport = obj[:srcport]
      #         dstport, protocol = obj[:dstport], obj[:protocol]
      #         src = [src].flatten()
      #         dst = [dst].flatten()
      #         srcport = [srcport].flatten()
      #         dstport = [dstport].flatten()

      #         combine_arrays(src, dst, srcport, dstport){|s, d, sp, dp|
      #           result[dcname][pgname] << {
      #             description: "desc1", 
      #             src: s, dst: d,
      #             srcport: sp, dstport: dp,
      #             protocol: protocol, action: obj[:action]
      #           }
      #         }
              
      #       end
      #     end
      #   end
      #   result
      # end

      # def to_s
      #   to_h
      # end
    end
  
    include RuleOperatorModule
    attr_accessor :rules, :portgroups

    def initialize()
      @portgroups = []
      @rules = Rules.new()
    end

    def assign_portgroup(dcname:, portgroupname:, address:)
      @portgroups << {
        dcname: dcname,
        portgroupname: portgroupname,
        address: address
      }
    end

    def add_rule(dcname:, pgname:, description:, src:, dst:, srcport:, dstport:, protocol:, action:)
      @rules.add_rule(dcname: dcname, pgname: pgname,
        rule: {
          description: description, src: src, dst: dst, srcport: srcport, dstport: dstport, protocol: protocol, action: action,
        }
      )
    end
  end
end