###############################################################
# Basic home/office iptables
###############################################################

###########
# NAT table
###########

# nat-overload
iptables --table nat --append POSTROUTING --out-interface wan --jump MASQUERADE

##############
# FILTER table
##############
# accept input from lan
iptables --table filter --append INPUT --in-interface br-lan --jump ACCEPT

# accept forward from lan
iptables --table filter --append FORWARD --in-interface br-lan --jump ACCEPT

# accept established/related
iptables --table filter --append FORWARD --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT
iptables --table filter --append INPUT --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT

# accept icmp 
iptables --table filter --append INPUT --proto icmp --icmp-type 8 --in-interface wan --jump ACCEPT

# accept dhcp from outside
iptables --table filter --append INPUT --proto udp --sport 67 --dport 68 --in-interface wan --jump ACCEPT

# accept dns replies from outside
# put DNS servers address to --source attribute
iptables --table filter --append INPUT --proto udp --source %s --dport 53 --in-interface wan --jump ACCEPT
iptables --table filter --append INPUT --proto tcp --source %s --dport 53 --in-interface wan --jump ACCEPT

# default policy to drop on INPUT and FORWARD chains
iptables --policy INPUT DROP
iptables --policy FORWARD DROP
