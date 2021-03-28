require 'forwardable'


class Ramparts::Routers::Vds1
  # ビジネスロジックを含むクラス
  # リポジトリとfilter 定義をつなぐ役割を持つ
  # 次のルールを利用する
  # - 自機のinterfaceをdstとするルールを利用する
  # - 自機のinterfaceをsrcとするルールの戻りを利用する
  # ルールの自動集約は行わない

  extend Forwardable
  def_delegators :@engine, :assign_portgroup, :add_rule
  
  def initialize(repository)
    @engine = Ramparts::Routers::Base::Vds.new
    @repository = repository
  end

  def create_rules
    # 自PortGroupのアドレスがdstであるルールを抽出する

    @repository.rules.each do |rule|
      @engine.portgroups.each do |portgroup|
        if rule.dst.name == 'any'
          dst = nil
        else
          if IPAddr.new(portgroup[:address]).include?(IPAddr.new(rule.dst.address))
            dst = rule.dst.address
          else
            next
          end
        end
        if rule.src.name == 'any'
          src = nil
        else
          src = rule.src.address
        end
        if rule.srcport.name == 'any'
          srcport = nil
        else
          srcport = rule.srcport.port
        end
        if rule.service.name == 'any'
          dstport = nil
          protocol = nil
        else
          dstport = rule.service.port
          protocol = rule.service.protocol
        end
        dcname = portgroup[:dcname]
        pgname = portgroup[:portgroupname]
        @engine.add_rule(dcname: dcname, pgname: pgname,
          description: "#{rule[:action][0].upcase}_#{rule.src.name}_#{rule.dst.name}",
          src: src, dst: dst, srcport: srcport, dstport: dstport,
          protocol: protocol, action: rule[:action])
      end
    end

    # 自PortGroupのアドレスがsrcであるルールの戻りを抽出する
    @repository.rules.each do |rule|
      @engine.portgroups.each do |portgroup|
        if rule.src.name == 'any'
          dst = nil
        else
          if IPAddr.new(portgroup[:address]).include?(IPAddr.new(rule.src.address))
            dst = rule.src.address
          else
            next
          end
        end
        if rule.dst.name == 'any'
          src = nil
        else
          src = rule.dst.address
        end
        if rule.srcport.name == 'any'
          dstport = nil
        else
          dstport = rule.srcport.port
        end
        if rule.service.name == 'any'
          srcport = nil
          protocol = nil
        else
          srcport = rule.service.port
          protocol = rule.service.protocol
        end
        dcname = portgroup[:dcname]
        pgname = portgroup[:portgroupname]
        @engine.add_rule(dcname: dcname, pgname: pgname,
          description: "#{rule[:action][0].upcase}_#{rule.src.name}_#{rule.dst.name}_RET",
          src: src, dst: dst, srcport: srcport, dstport: dstport,
          protocol: protocol, action: rule[:action])
      end
    end
    @engine.rules
  end     
end
