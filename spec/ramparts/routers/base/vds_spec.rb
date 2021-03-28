require "spec_helper"

RSpec.describe Ramparts::Routers::Base::Vds do
  subject { Ramparts::Routers::Base::Vds.new }

  it "ルールからfilterを生成できる" do
    subject.add_rule(
      dcname: 'dc1', pgname: 'pg11',
      description: 'desc1',
      src: '192.168.0.0/24', srcport: '32768-65535',
      dst: '10.0.1.50/32',   dstport: '53',
      protocol: 'udp', action: 'accept'
    )
    actual = subject.rules.to_h
    expect(actual).to eq({
      "dc1" => {
        "pg11" => [{
          description: 'desc1',
          src: '192.168.0.0/24', srcport: '32768-65535',
          dst: '10.0.1.50/32',   dstport: '53',
          protocol: 'udp', action: 'accept'
        }]
      }
    })
  end

  it "any(nil)を利用したルールからfilterを生成できる" do
    subject.add_rule(
      dcname: 'dc1', pgname: 'pg11',
      description: 'desc1',
      src: nil, srcport: nil,
      dst: nil,   dstport: nil,
      protocol: nil, action: 'accept'
    )
    actual = subject.rules.to_h
    expect(actual).to eq({
      "dc1" => {
        "pg11" => [{
          description: 'desc1',
          src: 'any', srcport: 'any',
          dst: 'any',   dstport: 'any',
          protocol: 'any', action: 'accept'
        }]
      }
    })
  end
end
