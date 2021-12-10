DNS_FILE="/tmp/resolv.conf.d/resolv.conf.auto"
DNS_SERVERS = {}


-- helper
local function startswith(str, prefix)
    return str:find(prefix, 1, true) == 1
end


-- fill DNS_SERVERS from file
print('Reading DNS servers')
for line in io.lines(DNS_FILE) do
    if startswith(line, 'nameserver') then
        local replace = '^nameserver '
        line = line:gsub(replace, '')
        table.insert(DNS_SERVERS, line)
    end
end


print('Creating iptables rules')
-- nat overload
os.execute('iptables --table nat --append POSTROUTING --out-interface wan --jump MASQUERADE')

-- accept input from lan
os.execute('iptables --table filter --append INPUT --in-interface br-lan --jump ACCEPT')

-- accept forward from lan
os.execute('iptables --table filter --append FORWARD --in-interface br-lan --jump ACCEPT')

-- accept established/related
os.execute('iptables --table filter --append FORWARD --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT')
os.execute('iptables --table filter --append INPUT --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT')

-- accept icmp
os.execute('iptables --table filter --append INPUT --proto icmp --icmp-type 8 --in-interface wan --jump ACCEPT')

-- accept dhcp from outside
os.execute('iptables --table filter --append INPUT --proto udp --sport 67 --dport 68 --in-interface wan --jump ACCEPT')

-- accept dsn replies from each dns server
for i, server in pairs(DNS_SERVERS) do
    local udp_cmd = string.format(
        'iptables --table filter --append INPUT --proto udp --source %s --dport 53 --in-interface wan --jump ACCEPT',
        server
    )
    local tcp_cmd = string.format(
        'iptables --table filter --append INPUT --proto tcp --source %s --dport 53 --in-interface wan --jump ACCEPT',
        server
    )
    os.execute(udp_cmd)
    os.execute(tcp_cmd)
end

-- rewrite policy for INPUT and FORWARD
os.execute('iptables --policy INPUT DROP')
os.execute('iptables --policy FORWARD DROP')
