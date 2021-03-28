require "spec_helper"

RSpec.describe Ramparts::Routers::Vds1 do
  let(:repository){ Ramparts::Repository.new() }
  subject { Ramparts::Routers::Vds1.new(repository) }

  it "複数のインタフェースを持つルーターについて、該当インタフェースごとのfilterをオブジェクト名を使用したルールから生成できる" do
    repository.add_host(name: 'network11', address: '192.168.11.0/24')
    repository.add_host(name: 'network12', address: '192.168.12.0/24')
    repository.add_service(name: 'dnsudp', service: '53/udp')
    repository.add_port(name: 'highport32768', port: '32768-65535')
    repository.add_rule(
      src: 'network11', dst: 'network12',
      srcport: 'highport32768', service: 'dnsudp',
      action: 'accept', target: '.*'
    )
    subject.assign_portgroup(dcname: 'vmdc01', portgroupname: 'pg11', address: '192.168.11.0/24')
    subject.assign_portgroup(dcname: 'vmdc01', portgroupname: 'pg12', address: '192.168.12.0/24')
    actual = subject.create_rules().to_h
    expect(actual).to eq({
      "vmdc01" => {
        "pg11" => [
          {
            description: "A_network11_network12_RET",
            src: "192.168.12.0/24",
            dst: "192.168.11.0/24",
            srcport: "53",
            dstport: "32768-65535",
            protocol: "udp",
            action: "accept"
          }
        ],
        "pg12" => [
          {
            description: "A_network11_network12",
            src: "192.168.11.0/24",
            dst: "192.168.12.0/24",
            srcport: "32768-65535",
            dstport: "53",
            protocol: "udp",
            action: "accept"
          }
        ],
      }
    })
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
    subject.assign_portgroup(dcname: 'vmdc01', portgroupname: 'pg11', address: '192.168.11.0/24')
    subject.assign_portgroup(dcname: 'vmdc01', portgroupname: 'pg12', address: '192.168.12.0/24')
    actual = subject.create_rules().to_h
    expect(actual).to eq({
      "vmdc01" => {
        "pg11" => [
          {
            description: "A_any_any",
            src: "any",
            dst: "any",
            srcport: "any",
            dstport: "any",
            protocol: "any",
            action: "accept"
          },
          {
            description: "A_any_any_RET",
            src: "any",
            dst: "any",
            srcport: "any",
            dstport: "any",
            protocol: "any",
            action: "accept"
          }
        ],
        "pg12" => [
          {
            description: "A_any_any",
            src: "any",
            dst: "any",
            srcport: "any",
            dstport: "any",
            protocol: "any",
            action: "accept"
          },
          {
            description: "A_any_any_RET",
            src: "any",
            dst: "any",
            srcport: "any",
            dstport: "any",
            protocol: "any",
            action: "accept"
          }
        ],
      }
    })
  end
end
