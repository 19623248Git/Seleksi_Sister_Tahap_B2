# OSPF

## Gokouloryn

### Gokouloryn Gov Router
```
Router(config)#ip access-list extended gov_in
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit tcp any 192.168.2.0 0.0.0.255 established
Router(config-ext-nacl)#permit icmp any 192.168.2.0 0.0.0.255 echo-reply
Router(config-ext-nacl)#permit udp any eq 53 192.168.2.0 0.0.0.255
Router(config-ext-nacl)#permit udp any eq 67 192.168.2.0 0.0.0.255 eq 68
Router(config-ext-nacl)#permit ip 192.168.4.0 0.0.0.255 192.168.2.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.6.0 0.0.0.255 192.168.2.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.10.0 0.0.0.255 192.168.2.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.14.0 0.0.0.255 192.168.2.0 0.0.0.255
Router(config-ext-nacl)#exit
Router(config)#ip access-list extended gov_out
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit udp 192.168.2.0 0.0.0.255 any eq 53
Router(config-ext-nacl)#permit udp 192.168.2.0 0.0.0.255 any eq 67
Router(config-ext-nacl)#permit tcp 192.168.2.0 0.0.0.255 any eq 443
Router(config-ext-nacl)#permit icmp 192.168.2.0 0.0.0.255 any echo
Router(config-ext-nacl)#permit ip 192.168.2.0 0.0.0.255 192.168.4.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.2.0 0.0.0.255 192.168.6.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.2.0 0.0.0.255 192.168.10.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.2.0 0.0.0.255 192.168.14.0 0.0.0.255
Router(config-ext-nacl)#exit
Router(config)#interface GigabitEthernet0/0
Router(config-if)#ip access-group gov_in in
Router(config-if)#ip access-group gov_out out
```

### Gokouloryn Ent Router
```
Router(config)#ip access-list extended ent_in
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit ip 192.168.2.0 0.0.0.255 192.168.4.0 0.0.0.255
Router(config-ext-nacl)#permit tcp any 192.168.4.0 0.0.0.255 eq 443
Router(config-ext-nacl)#permit udp any 192.168.4.0 0.0.0.255 eq 53
Router(config-ext-nacl)#permit udp any 192.168.4.0 0.0.0.255 eq 67
Router(config-ext-nacl)#permit udp any 192.168.4.0 0.0.0.255 eq 68
Router(config-ext-nacl)#permit udp any eq domain 192.168.4.0 0.0.0.255
Router(config-ext-nacl)#exit
Router(config)#ip access-list extended ent_out
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit udp host 192.168.4.4 any eq 67
Router(config-ext-nacl)#permit ip 192.168.4.0 0.0.0.255 192.168.2.0 0.0.0.255
Router(config-ext-nacl)#permit tcp 192.168.4.0 0.0.0.255 any established
Router(config-ext-nacl)#permit udp 192.168.4.0 0.0.0.255 eq 53 any
Router(config-ext-nacl)#exit
Router(config)#interface GigabitEthernet0/0
Router(config-if)#ip access-group ent_in in
Router(config-if)#ip access-group ent_out out
```


## Rurinthia

### Rurinthia Gov Router
```
Router(config)#ip access-list extended gov_in
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit tcp any 192.168.6.0 0.0.0.255 established
Router(config-ext-nacl)#permit icmp any 192.168.6.0 0.0.0.255 echo-reply
Router(config-ext-nacl)#permit udp any eq 53 192.168.6.0 0.0.0.255
Router(config-ext-nacl)#permit udp any eq 67 192.168.6.0 0.0.0.255 eq 68
Router(config-ext-nacl)#permit ip 192.168.8.0 0.0.0.255 192.168.6.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.2.0 0.0.0.255 192.168.6.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.10.0 0.0.0.255 192.168.6.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.14.0 0.0.0.255 192.168.6.0 0.0.0.255
Router(config-ext-nacl)#exit
Router(config)#ip access-list extended gov_out
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit udp 192.168.6.0 0.0.0.255 any eq 53
Router(config-ext-nacl)#permit udp 192.168.6.0 0.0.0.255 any eq 67
Router(config-ext-nacl)#permit tcp 192.168.6.0 0.0.0.255 any eq 443
Router(config-ext-nacl)#permit icmp 192.168.6.0 0.0.0.255 any echo
Router(config-ext-nacl)#permit ip 192.168.6.0 0.0.0.255 192.168.8.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.6.0 0.0.0.255 192.168.2.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.6.0 0.0.0.255 192.168.10.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.6.0 0.0.0.255 192.168.14.0 0.0.0.255
Router(config-ext-nacl)#exit
Router(config)#interface GigabitEthernet0/0
Router(config-if)#ip access-group gov_in in
Router(config-if)#ip access-group gov_out out
```


### Rurinthia Ent Router
```
Router(config)#ip access-list extended ent_in
Router(config-ext-nacl)# permit ospf any any
Router(config-ext-nacl)# permit ip 192.168.6.0 0.0.0.255 192.168.8.0 0.0.0.255
Router(config-ext-nacl)# permit tcp any 192.168.8.0 0.0.0.255 eq 443
Router(config-ext-nacl)# permit udp any 192.168.8.0 0.0.0.255 eq 53
Router(config-ext-nacl)# permit udp any 192.168.8.0 0.0.0.255 eq 67
Router(config-ext-nacl)# permit udp any 192.168.8.0 0.0.0.255 eq 68
Router(config-ext-nacl)# permit udp any eq domain 192.168.8.0 0.0.0.255
Router(config-ext-nacl)#ip access-list extended ent_out
Router(config-ext-nacl)# permit ospf any any
Router(config-ext-nacl)# permit udp host 192.168.8.4 any eq 67
Router(config-ext-nacl)# permit ip 192.168.8.0 0.0.0.255 192.168.6.0 0.0.0.255
Router(config-ext-nacl)# permit tcp 192.168.8.0 0.0.0.255 any established
Router(config-ext-nacl)# permit udp 192.168.8.0 0.0.0.255 eq 53 any
Router(config-ext-nacl)#interface GigabitEthernet0/0
Router(config-if)# ip access-group ent_in in
Router(config-if)# ip access-group ent_out out
```


## Kuronexus

### Kuronexus Gov Router
```
Router(config)#ip access-list extended gov_in
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit tcp any 192.168.10.0 0.0.0.255 established
Router(config-ext-nacl)#permit icmp any 192.168.10.0 0.0.0.255 echo-reply
Router(config-ext-nacl)#permit udp any eq 53 192.168.10.0 0.0.0.255
Router(config-ext-nacl)#permit udp any eq 67 192.168.10.0 0.0.0.255 eq 68
Router(config-ext-nacl)#permit ip 192.168.12.0 0.0.0.255 192.168.10.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.2.0 0.0.0.255 192.168.10.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.6.0 0.0.0.255 192.168.10.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.14.0 0.0.0.255 192.168.10.0 0.0.0.255
Router(config-ext-nacl)#exit
Router(config)#ip access-list extended gov_out
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit udp 192.168.10.0 0.0.0.255 any eq 53
Router(config-ext-nacl)#permit udp 192.168.10.0 0.0.0.255 any eq 67
Router(config-ext-nacl)#permit tcp 192.168.10.0 0.0.0.255 any eq 443
Router(config-ext-nacl)#permit icmp 192.168.10.0 0.0.0.255 any echo
Router(config-ext-nacl)#permit ip 192.168.10.0 0.0.0.255 192.168.12.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.10.0 0.0.0.255 192.168.2.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.10.0 0.0.0.255 192.168.6.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.10.0 0.0.0.255 192.168.14.0 0.0.0.255
Router(config-ext-nacl)#exit
Router(config)#interface GigabitEthernet0/0
Router(config-if)#ip access-group gov_in in
Router(config-if)#ip access-group gov_out out
```


### Kuronexus Ent Router
```
Router(config)#ip access-list extended ent_in
Router(config-ext-nacl)# permit ospf any any
Router(config-ext-nacl)# permit ip 192.168.10.0 0.0.0.255 192.168.12.0 0.0.0.255
Router(config-ext-nacl)# permit tcp any 192.168.12.0 0.0.0.255 eq 443
Router(config-ext-nacl)# permit udp any 192.168.12.0 0.0.0.255 eq 53
Router(config-ext-nacl)# permit udp any 192.168.12.0 0.0.0.255 eq 67
Router(config-ext-nacl)# permit udp any 192.168.12.0 0.0.0.255 eq 68
Router(config-ext-nacl)# permit udp any eq domain 192.168.12.0 0.0.0.255
Router(config-ext-nacl)#ip access-list extended ent_out
Router(config-ext-nacl)# permit ospf any any
Router(config-ext-nacl)# permit udp host 192.168.12.4 any eq 67
Router(config-ext-nacl)# permit ip 192.168.12.0 0.0.0.255 192.168.10.0 0.0.0.255
Router(config-ext-nacl)# permit tcp 192.168.12.0 0.0.0.255 any established
Router(config-ext-nacl)# permit udp 192.168.12.0 0.0.0.255 eq 53 any
Router(config-ext-nacl)#interface GigabitEthernet0/0
Router(config-if)# ip access-group ent_in in
Router(config-if)# ip access-group ent_out out
```


## Yamindralia

### Yamindralia Gov Router
```
Router(config)#ip access-list extended gov_in
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit tcp any 192.168.14.0 0.0.0.255 established
Router(config-ext-nacl)#permit icmp any 192.168.14.0 0.0.0.255 echo-reply
Router(config-ext-nacl)#permit udp any eq 53 192.168.14.0 0.0.0.255
Router(config-ext-nacl)#permit udp any eq 67 192.168.14.0 0.0.0.255 eq 68
Router(config-ext-nacl)#permit ip 192.168.16.0 0.0.0.255 192.168.14.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.2.0 0.0.0.255 192.168.14.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.6.0 0.0.0.255 192.168.14.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.10.0 0.0.0.255 192.168.14.0 0.0.0.255
Router(config-ext-nacl)#exit
Router(config)#ip access-list extended gov_out
Router(config-ext-nacl)#permit ospf any any
Router(config-ext-nacl)#permit udp 192.168.14.0 0.0.0.255 any eq 53
Router(config-ext-nacl)#permit udp 192.168.14.0 0.0.0.255 any eq 67
Router(config-ext-nacl)#permit tcp 192.168.14.0 0.0.0.255 any eq 443
Router(config-ext-nacl)#permit icmp 192.168.14.0 0.0.0.255 any echo
Router(config-ext-nacl)#permit ip 192.168.14.0 0.0.0.255 192.168.16.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.14.0 0.0.0.255 192.168.2.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.14.0 0.0.0.255 192.168.6.0 0.0.0.255
Router(config-ext-nacl)#permit ip 192.168.14.0 0.0.0.255 192.168.10.0 0.0.0.255
Router(config-ext-nacl)#exit
Router(config)#interface GigabitEthernet0/0
Router(config-if)#ip access-group gov_in in
Router(config-if)#ip access-group gov_out out
```


### Yamindralia Ent Router
```
Router(config)#ip access-list extended ent_in
Router(config-ext-nacl)# permit ospf any any
Router(config-ext-nacl)# permit ip 192.168.14.0 0.0.0.255 192.168.16.0 0.0.0.255
Router(config-ext-nacl)# permit tcp any 192.168.16.0 0.0.0.255 eq 443
Router(config-ext-nacl)# permit udp any 192.168.16.0 0.0.0.255 eq 53
Router(config-ext-nacl)# permit udp any 192.168.16.0 0.0.0.255 eq 67
Router(config-ext-nacl)# permit udp any 192.168.16.0 0.0.0.255 eq 68
Router(config-ext-nacl)#permit udp any eq domain 192.168.16.0 0.0.0.255
Router(config-ext-nacl)#ip access-list extended ent_out
Router(config-ext-nacl)# permit ospf any any
Router(config-ext-nacl)# permit udp host 192.168.16.4 any eq 67
Router(config-ext-nacl)# permit ip 192.168.16.0 0.0.0.255 192.168.14.0 0.0.0.255
Router(config-ext-nacl)# permit tcp 192.168.16.0 0.0.0.255 any established
Router(config-ext-nacl)# permit udp 192.168.16.0 0.0.0.255 eq 53 any
Router(config-ext-nacl)#interface GigabitEthernet0/0
Router(config-if)# ip access-group ent_in in
Router(config-if)# ip access-group ent_out out
```



