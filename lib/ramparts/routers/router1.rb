require 'forwardable'


class Ramparts::Routers::Router1
  # ビジネスロジックを含むクラス
  # リポジトリとfilter 定義をつなぐ役割を持つ
  # 自機のinterfaceをsrcとするルールのみ利用する
  # ルールの自動集約は行わない

  extend Forwardable
  def_delegators :@engine, :assign_interface, :add_rule
  
  def initialize(repository)
    @engine = Ramparts::Routers::Base::Junos.new
    @repository = repository
  end

  def create_rules
    # 自機のinterfaceにinするルールを抽出する
    # repository1 は src,dstなどは配列ではない

    @repository.rules.each do |rule|
      @engine.interfaces.each do |interface|
        if rule.src.name == 'any'
          src = nil
        else
          if IPAddr.new(interface[:address]).include?(IPAddr.new(rule.src.address))
            src = rule.src.address
          else
            next
          end
        end
        if rule.dst.name == 'any'
          dst = nil
        else
          dst = rule.dst.address
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
        term = "#{rule.action[0].upcase}_#{rule.src.name}_#{rule.dst.name}"
        @engine.add_rule(filtername: interface[:filtername], term: term,
          src: src, dst: dst,
          srcport: srcport, dstport: dstport,
          protocol: protocol, action: rule.action)
      end
    end

    # @repository.rules.each do |p_rule|
    #   @engine.interfaces.each do |interface|
    #     rule = Marshal.load(Marshal.dump(p_rule))
    #     src = rule[:src].select{|s| 
    #       ho = Host.new(s, @repository)
    #       IPAddr.new(interface[:address]).include?(IPAddr.new(ho.address))
    #     }
    #     filtername = interface[:filtername]
    #     term = rule[:name]
    #     rule = rule.tap{|r| r.delete(:name); r}.merge(src: src)
    #     @engine.add_rule(filtername: filtername, term: term, rule: rule)
    #   end
    # end

    @engine.rules
  end     
end
