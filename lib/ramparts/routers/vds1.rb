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

  def normalize_host(host)
    if host.name == 'any'
      return nil
    else
      return host.address
    end
  end

  def normalize_port(port)
    if port.name == 'any'
      return nil
    else
      return port.port
    end
  end

  def normalize_service(service)
    if service.name == 'any'
      return [nil, nil]
    else
      return [service.port, service.protocol]
    end
  end

  def create_rules

    @repository.rules.select{|rule| rule.target =~ 'vds1'}.each do |rule|
      # 自PortGroupのアドレスがdstであるルールを抽出する
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
        src = normalize_host(rule.src)
        srcport = normalize_port(rule.srcport)
        dstport, protocol = normalize_service(rule.service)

        dcname = portgroup[:dcname]
        pgname = portgroup[:portgroupname]
        @engine.add_rule(dcname: dcname, pgname: pgname,
          description: "#{rule[:action][0].upcase}_#{rule.src.name}_#{rule.dst.name}",
          src: src, dst: dst, srcport: srcport, dstport: dstport,
          protocol: protocol, action: rule[:action])
      end
    
      # 自PortGroupのアドレスがsrcであるルールの戻りを抽出する
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
        src = normalize_host(rule.dst)
        dstport = normalize_port(rule.srcport)
        srcport, protocol = normalize_service(rule.service)

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


class Ramparts::Routers::Vds1a
  # ビジネスロジックを含むクラス
  # リポジトリとfilter 定義をつなぐ役割を持つ
  # 次のルールを利用する
  # - 自機のinterfaceをdstとするルールを利用する
  # - 自機のinterfaceをsrcとするルールの戻りを利用する
  # ルールの自動集約は行わない

  extend Forwardable
  def_delegators :@engine, :assign_portgroup, :add_rule
  
  def initialize(repository, name:)
    @engine = Ramparts::Routers::Base::Vds.new
    @repository = repository
    @name = name
  end

  def normalize_host(host)
    if host.name == 'any'
      return nil
    else
      return host.address
    end
  end

  def normalize_port(port)
    if port.name == 'any'
      return nil
    else
      return port.port
    end
  end

  def normalize_service(service)
    if service.name == 'any'
      return [nil, nil]
    else
      return [service.port, service.protocol]
    end
  end

  def create_rules

    @repository.rules.select{|rule| rule.target =~ name}.each do |rule|
      # 自PortGroupのアドレスがdstであるルールを抽出する
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
        src = normalize_host(rule.src)
        srcport = normalize_port(rule.srcport)
        dstport, protocol = normalize_service(rule.service)

        dcname = portgroup[:dcname]
        pgname = portgroup[:portgroupname]
        @engine.add_rule(dcname: dcname, pgname: pgname,
          description: "#{rule[:action][0].upcase}_#{rule.src.name}_#{rule.dst.name}",
          src: src, dst: dst, srcport: srcport, dstport: dstport,
          protocol: protocol, action: rule[:action])
      end
    
      # 自PortGroupのアドレスがsrcであるルールの戻りを抽出する
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
        src = normalize_host(rule.dst)
        dstport = normalize_port(rule.srcport)
        srcport, protocol = normalize_service(rule.service)

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
