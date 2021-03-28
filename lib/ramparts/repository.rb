require 'ipaddr'
require 'forwardable'

class Ramparts::RepositoryFileLoader
  def initialize(filename)
    @filename = filename
    @meta = nil
    @sep = nil
    @data = []
    @meta, @sep, @data = _load(@filename)
  end

  def _load(filename)
    tmp = File.readlines(filename)
    if sep_index = tmp.find_index{|line| line =~ %r{----*}}
      meta = tmp[0..(sep_index-1)]
      sep = tmp[sep_index]
      data = tmp[sep_index+1..-1]
    else
      meta = nil
      sep = nil
      data = tmp
    end
    data = data.map{|line| line.split(',').map(&:strip) }
    [meta, sep, data]
  end

  def _save(filename, meta, sep, data)
    File.open(filename, "wb"){|f|
      f.puts meta if meta
      f.puts sep if sep
      data.each{|row|
        f.puts row.join(', ')
      }
    }
  end

  def save(filename, format: true)
    meta = @meta
    sep = @sep
    data = @data
    if format
      widths = data.transpose.map {|x| x.map(&:strip).map(&:length).max }
      data = data.map{|row|
        row.zip(widths).map{|value, width| value.strip.ljust(width) }
      }
    end
    _save(filename, meta, sep, data)
  end
end

class Ramparts::Repository
  class Host
    attr_reader :name, :address
  
    def initialize(name:, address:)
      @name = name
      @address = address
  
      # begin
      #   IPAddr.new(hostname_or_address)
      #   @address = hostname_or_address  # ipaddr
      #   @hostname = hostname_or_address # ipaddr
      # rescue IPAddr::InvalidAddressError
      #   @address = repository.get_host(hostname_or_address)[:address] # ipaddr
      #   @hostname = hostname_or_address # hostname
      # end
  
      # raise Exception.new("host object not found #{hostname_or_address}") if @address.nil?
    end
  end
  
  class Port
    attr_reader :name, :port

    def initialize(name:, port:)
      @name = name
      @port = port
    end
  end

  class Service
    attr_reader :name, :service

    def initialize(name:, service:)
      @name = name
      @service = service
    end

    def port
      @service.split('/')[0]
    end

    def protocol
      @service.split('/')[1]
    end
  end

  class Rule
    attr_reader :src, :dst, :srcport, :service, :action, :target

    def initialize(target: nil, src: nil , dst: nil, srcport: nil, service: nil, action:)
      raise "src is not Host class" if not src.nil? and src.class != Host
      raise "dst is not Host class" if not dst.nil? and dst.class != Host
      raise "srcport is not Port class" if not srcport.nil? and srcport.class != Port
      raise "service is not Service class" if not service.nil? and service.class != Service
      @target = target
      @src = src
      @dst = dst
      @srcport = srcport
      @service = service
      @action = action
    end

    def [](key)
      self.instance_variable_get("@#{key}")
    end

    def to_h
      return ({
        src: @src,
        srcport: @srcport,
        dst: @dst,
        service: @service,
        action: @action,
      })
    end
  end
  
  class Rules
    extend Forwardable
    include Enumerable
    def_delegators :@rules, :each

    def initialize
      @rules = []
    end

    def <<(rule)
      @rules << rule
    end

    def flatten_grep(target: :src)
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

      @rules.each do |rule|
        result_src = []
        rule = rule.to_h
        name = rule[:name]
        src = rule[:src]
        dst = rule[:dst]
        srcport = rule[:srcport]
        dstport, protocol = rule[:dstport], rule[:protocol]
        src = [src].flatten()
        dst = [dst].flatten()
        srcport = [srcport].flatten()
        dstport = [dstport].flatten()
        combine_arrays(src){|s|
          ret = yield ({
            name: "#{name}",
            src: s, dst: dst,
            srcport: srcport, dstport: dstport,
            protocol: protocol, action: rule[:action]
          })
          result_src << s if ret
        }
      end
    end
  end
end


class Ramparts::Repository
  attr_reader :rules
  LABELS = %w(src dst srcport service action).map(&:to_sym)

  def initialize()
    @hosts = []
    @ports = []
    @rules = []
    @services = []

    @hosts << Host.new(
      name:     'any',
      address:  '0.0.0.0/0',
    )
    @ports << Port.new(
      name: 'any',
      port: 0,
    )
    @services << Service.new(
      name: 'any',
      service: '0/any',
    )
  end

  def parse_segment(arr)
    result = {}
    sep_index = arr.find_index{|line| line =~ %r{----*}}
    if sep_index
      meta = arr[0..(sep_index-1)]
      sep = arr[sep_index]
      ruledata = arr[sep_index+1..-1]
    else
      meta = nil
      sep = nil
      ruledata = arr
    end

    meta.each{|line|
      case line
      when %r{target:(.+)}
        result[:target] = $1
      else
        STDERR.puts "Unknown meta: #{line}"
      end
    }
    result[:sep] = sep
    result[:ruledata] = ruledata
    result
  end
  
  def parse_ruledata(arr)
    segments = []
    arr.chunk{|line| line =~ %r{====*} ? :segment_sep : :data}.reject{|key, segment| key == :segment_sep}
       .each{|_, segment|
        segments << parse_segment(segment)
       }
    segments
  end

  def load_ruledata(io)
    tmp = io.readlines
    segments = parse_ruledata(tmp)
    segments.each{|data|
      csv = data[:ruledata].map{|line| line.split(',').map(&:strip) }
      csv[1..-1].each{|row|
        add_rule( **LABELS.zip(row).to_h , target: data[:target])
      }
    }
  end

  def load_rulefile(filename)
    # csv
    File.open(filename){|f|
      load_ruledata(f)
    }
  end

  def load_some(filename)
    # yaml
    data = YAML.load( File.read(filename) )
    data['host'].each{|name, value|
      add_host(name: name, address: value)
    }
    # data['object_group']
    data['port'].each{|name, value|
      add_port(name: name, port: value)
    }
    data['service'].each{|name, value|
      add_service(name: name, service: value)
    }
    # data['service_group']
  end
  
  def load_dir(dirpath)
    # host, port, service
    load_some('sample_data/def.yml')

    # rule
    Dir.glob("#{dirpath}/*.csv"){|filename|
      load_rulefile(filename)
    }
  end

  def add_host(**kwargs)
    tmp = Host.new(
      name:     kwargs[:name],
      address:  kwargs[:address],
    )
    @hosts << tmp
    tmp
  end

  def add_port(**kwargs)
    tmp = Port.new(
      name: kwargs[:name],
      port: kwargs[:port],
    )
    @ports << tmp
    tmp
  end

  def add_service(name:, service:)
    tmp = Service.new(
      name: name,
      service: service,
    )
    @services << tmp
    tmp
  end

  def add_rule(src:, dst:, srcport:, service:, action:, target:)
    src = resolve_host(src)
    dst = resolve_host(dst)
    srcport = resolve_port(srcport)
    service = resolve_service(service)
    action = action
    rule = Rule.new(
      target: target,
      src: src, dst: dst,
      srcport: srcport, service: service, action: action
    )
    @rules << rule
    rule
  end

  def resolve_host(name, create_if_not_exists: true)
    tmp = @hosts.find{|e| e.name == name }
    if tmp.nil?
      if create_if_not_exists and name =~ %r{\d+\.\d+\.\d+\.\d+/\d+}
        return add_host(name: name, address: name)
      else
        raise "host not found. #{name}"
      end
    else
      return tmp
    end
  end

  def resolve_port(name, create_if_not_exists: true)
    tmp = @ports.find{|e| e.name == name }
    if tmp.nil?
      if create_if_not_exists and (name =~ %r{\d+} or name =~ %r{\d+-\d+})
        return add_port(name: name, port: name)
      else
        raise "port not found. #{name}"
      end
    else
      return tmp
    end
  end

  def resolve_service(name, create_if_not_exists: true)
    tmp = @services.find{|e| e.name == name }
    if tmp.nil?
      if create_if_not_exists and name =~ %r{\d+/\w+}
        return add_service(name: name, service: name)
      else
        raise "service not found. #{name}"
      end
    else
      return tmp
    end
  end
  # def get_port(name)
  #   @ports.select{|e| e[:name] == name }.first
  # end

  # def resolve_host(hostnames_or_address)
  #   [hostnames_or_address].flatten.map{|hostname_or_address|
  #     begin
  #       IPAddr.new(hostname_or_address)
  #       next hostname_or_address
  #     rescue IPAddr::InvalidAddressError
  #       next get_host(hostname_or_address)[:address]
  #     end
  #     raise Exception.new("host object not found #{hostname_or_address}") if @address.nil?
  #   }
  # end

  # def resolve_port(ports_or_portranges_or_portnames, protocol: nil, type:)
  #   result_ports = []
  #   result_protocol = nil
  #   tmp = [ports_or_portranges_or_portnames].flatten().map{|port_or_portrange_or_portname|
  #     if %r"\A\d+\z|\A\d+-\d+\z" =~ port_or_portrange_or_portname
  #       next {prortname: nil, port: port_or_portrange_or_portname, protocol: nil}
  #     else
  #       next get_port(port_or_portrange_or_portname)
  #     end
  #   }
  #   result_ports = tmp.map{|e| e[:port] }
  #   return result_ports if type == :src

  #   protocols = []
  #   protocols << protocol
  #   protocols += tmp.map{|e| e[:protocol] }
  #   protocols.flatten!
  #   protocols.reject!(&:nil?)
  #   if protocols.uniq.count == 1
  #     result_protocol = protocols.first
  #   else
  #     raise Exception.new("protocols does not same #{protocols}")
  #   end
  #   return [result_ports, result_protocol]
  # end
end
