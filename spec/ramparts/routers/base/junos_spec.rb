require "spec_helper"

RSpec.describe Ramparts::Routers::Base::Junos do
  subject { Ramparts::Routers::Base::Junos.new }

  it "シングルルールからfilterを生成できる" do
    subject.add_rule(
      filtername: 'irb001in', term: 'term1',
      src: '192.168.0.0/24', srcport: '32768-65535',
      dst: '10.0.1.50/32',   dstport: '53',
      protocol: 'udp', action: 'accept'
    )
    actual = subject.rules.to_a
    expect(actual).to eq([
      "set firewall filter irb001in term term1 source-address 192.168.0.0/24",
      "set firewall filter irb001in term term1 destination-address 10.0.1.50/32",
      "set firewall filter irb001in term term1 source-port 32768-65535",
      "set firewall filter irb001in term term1 destination-port 53",
      "set firewall filter irb001in term term1 protocol udp",
      "set firewall filter irb001in term term1 accept"
    ])
  end

  it "マルチルールからfilterを生成できる" do
    subject.add_rule(
      filtername: 'irb001in', term: 'term1',
      src: ['192.168.0.0/24', '192.168.0.1/32'], srcport: '32768-65535',
      dst: ['10.0.1.50/32', '10.0.1.51/32'], dstport: '53',
      protocol: 'udp', action: 'accept'
    )
    actual = subject.rules.to_a
    expect(actual).to eq([
      "set firewall filter irb001in term term1 source-address 192.168.0.0/24",
      "set firewall filter irb001in term term1 source-address 192.168.0.1/32",
      "set firewall filter irb001in term term1 destination-address 10.0.1.50/32",
      "set firewall filter irb001in term term1 destination-address 10.0.1.51/32",
      "set firewall filter irb001in term term1 source-port 32768-65535",
      "set firewall filter irb001in term term1 destination-port 53",
      "set firewall filter irb001in term term1 protocol udp",
      "set firewall filter irb001in term term1 accept"
    ])
  end


  it "any(nil)を使ったルールからfilterを生成できる" do
    subject.add_rule(
      filtername: 'irb001in', term: 'term1',
      src: nil, srcport: nil,
      dst: nil, dstport: nil,
      protocol: nil, action: 'accept'
    )
    actual = subject.rules.to_a
    expect(actual).to eq([
      "set firewall filter irb001in term term1 accept"
    ])
  end

  
end
