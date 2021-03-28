require "spec_helper"


RSpec.describe Ramparts::Routers::Router1 do
  let(:repository){ Ramparts::Repository.new() }
  subject { Ramparts::Routers::Router1.new(repository) }

  it "複数のインタフェースを持つルーターについて、該当インタフェースごとのfilterを生成できる" do
    repository.add_rule(
      src: '192.168.11.0/24', dst: '192.168.12.0/24',
      srcport: '32768-65535', service: '53/udp',
      action: 'accept', target: nil
    )
    repository.add_rule(
      src: '192.168.12.0/24', dst: '192.168.13.0/24',
      srcport: '32768-65535', service: '53/udp',
      action: 'accept', target: nil
    )
    subject.assign_interface(interfacename: 'irb11', filtername: 'irb11in', direction: 'in', address: '192.168.11.1/24')
    subject.assign_interface(interfacename: 'irb12', filtername: 'irb12in', direction: 'in', address: '192.168.12.1/24')
    actual = subject.create_rules().to_a
    expect(actual).to eq([
      "set firewall filter irb11in term A_192.168.11.0/24_192.168.12.0/24 source-address 192.168.11.0/24",
      "set firewall filter irb11in term A_192.168.11.0/24_192.168.12.0/24 destination-address 192.168.12.0/24",
      "set firewall filter irb11in term A_192.168.11.0/24_192.168.12.0/24 source-port 32768-65535",
      "set firewall filter irb11in term A_192.168.11.0/24_192.168.12.0/24 destination-port 53",
      "set firewall filter irb11in term A_192.168.11.0/24_192.168.12.0/24 protocol udp",
      "set firewall filter irb11in term A_192.168.11.0/24_192.168.12.0/24 accept",
      "set firewall filter irb12in term A_192.168.12.0/24_192.168.13.0/24 source-address 192.168.12.0/24",
      "set firewall filter irb12in term A_192.168.12.0/24_192.168.13.0/24 destination-address 192.168.13.0/24",
      "set firewall filter irb12in term A_192.168.12.0/24_192.168.13.0/24 source-port 32768-65535",
      "set firewall filter irb12in term A_192.168.12.0/24_192.168.13.0/24 destination-port 53",
      "set firewall filter irb12in term A_192.168.12.0/24_192.168.13.0/24 protocol udp",
      "set firewall filter irb12in term A_192.168.12.0/24_192.168.13.0/24 accept"
    ])
  end

  it "オブジェクト名を使用したシングルルールからfilterを生成できる" do
    repository.add_host(name: 'network11', address: '192.168.11.0/24')
    repository.add_host(name: 'network12', address: '192.168.12.0/24')
    repository.add_service(name: 'dnsudp', service: '53/udp')
    repository.add_port(name: 'highport32768', port: '32768-65535')
    repository.add_rule(
      src: 'network11', dst: 'network12',
      srcport: 'highport32768', service: 'dnsudp',
      action: 'accept', target: '.*'
    )
    subject.assign_interface(interfacename: 'irb11', filtername: 'irb11in', direction: 'in', address: '192.168.11.1/24')
    actual = subject.create_rules().to_a
    expect(actual).to eq([
      "set firewall filter irb11in term A_network11_network12 source-address 192.168.11.0/24",
      "set firewall filter irb11in term A_network11_network12 destination-address 192.168.12.0/24",
      "set firewall filter irb11in term A_network11_network12 source-port 32768-65535",
      "set firewall filter irb11in term A_network11_network12 destination-port 53",
      "set firewall filter irb11in term A_network11_network12 protocol udp",
      "set firewall filter irb11in term A_network11_network12 accept"
    ])
  end


  it "anyオブジェクト名を使用したシングルルールからfilterを生成できる" do
    repository.add_host(name: 'network11', address: '192.168.11.0/24')
    repository.add_host(name: 'network12', address: '192.168.12.0/24')
    repository.add_service(name: 'dnsudp', service: '53/udp')
    repository.add_port(name: 'highport32768', port: '32768-65535')
    repository.add_rule(
      src: 'any', dst: 'any',
      srcport: 'any', service: 'any',
      action: 'accept', target: '.*'
    )
    subject.assign_interface(interfacename: 'irb11', filtername: 'irb11in', direction: 'in', address: '192.168.11.1/24')
    actual = subject.create_rules().to_a
    expect(actual).to eq([
      "set firewall filter irb11in term A_any_any accept"
    ])
  end
end


RSpec.xdescribe Ramparts::Routers::Router1 do
  it "シングルルールから/24で集約したfilterを生成できる" do
    router = Ramparts::Routers::Router1.new()
    router.assign_interface(interfacename: 'irb100', filtername: 'irb100in', direction: 'in', address: '192.168.0.1/24')
    router.add_rule(
      name: 'TERM1',
      src: '192.168.0.2/32',
      srcport: '32768-65535',
      dst: '10.0.1.50/32',
      dstport: '53',
      protocol: 'udp',
      action: 'accept'
    )
    router.add_rule(
      name: 'TERM1',
      src: '192.168.0.3/32',
      srcport: '32768-65535',
      dst: '10.0.1.51/32',
      dstport: '53',
      protocol: 'udp',
      action: 'accept'
    )
    actual = router.create_filter_configuration_data()
    expect(actual).to eq({
      "irb100in" => {
        "TERM1" => {
          src: ['192.168.0.0/24'],
          srcport: ['32768-65535'],
          dst: ['10.0.1.0/24'],
          dstport: '53',
          protocol: 'udp',
          action: 'accept',
        }
      }
    })
  end
end

RSpec.xdescribe "e2e test" do
  it "a" do
    repository = Ramparts::Repository.new()
    repository.add_host(hostname: 'network0', address: '192.168.0.0/24')
    repository.add_host(hostname: 'network1', address: '192.168.1.0/24')
    repository.add_host(hostname: 'host0', address: '10.0.1.50/32')
    repository.add_host(hostname: 'host1', address: '10.0.1.51/32')
    repository.add_port(portname: 'udp53', protocol: 'udp', port: 53)
    repository.add_port(portname: 'default_highport1', port: '32768-65535')
    repository.add_rule(
      name: 'TERM1',
      src: ['network0', 'network1'],
      srcport: '32768-65535',
      dst: ['host0', 'host1'],
      dstport: '53',
      protocol: 'udp',
      action: 'accept'
    )
    
  end
end

# RSpec.xdescribe Ramparts::Routers::Base::Junos do
#   subject { Ramparts::Routers::Base::Junos.new }
#   LABELS = %w(filtername term src srcport dst dstport protocol action).map(&:to_sym)
#   patterns = []
#   patterns << [
#     LABELS.zip(%w(irb001in term1 192.168.0.0/24 32768-65535 10.0.1.50/32 53 udp accept)).to_h,
#     [
#       "set firewall filter irb001in term term1 source-address 192.168.0.0/24",
#       "set firewall filter irb001in term term1 destination-address 10.0.1.50/32",
#       "set firewall filter irb001in term term1 source-port 32768-65535",
#       "set firewall filter irb001in term term1 destination-port 53",
#       "set firewall filter irb001in term term1 protocol udp",
#       "set firewall filter irb001in term term1 accept"
#     ]
#   ]
#   where(:rule, :result) do
#     patterns
#   end

#   with_them do
#     it "ルールからfilterを生成できる" do
#       pp rule
#       subject.add_rule(**rule)
#       actual = subject.rules.to_a
#       expect(actual).to eq(result)
#     end
#   end
# end
