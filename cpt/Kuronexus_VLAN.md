# VLAN

## Kuronexus

### Kuronexus Public Switch
```
Switch(config)#vlan 30
Switch(config-vlan)#name Academy
Switch(config-vlan)#exit
Switch(config)#vlan 40
Switch(config-vlan)#name Business
Switch(config-vlan)#exit
Switch(config)#vlan 50
Switch(config-vlan)#name Communal
Switch(config-vlan)#exit
Switch(config)#interface range fa0/2-4
Switch(config-if-range)#sw m a
Switch(config-if-range)#exit
Switch(config)#interface FastEthernet0/2
Switch(config-if)#sw a vlan 30
Switch(config-if)#exit
Switch(config)#interface FastEthernet0/3
Switch(config-if)#sw a vlan 40
Switch(config-if)#exit
Switch(config)#interface FastEthernet0/4
Switch(config-if)#sw a vlan 50
Switch(config-if)#exit
Switch(config)#interface FastEthernet0/1
Switch(config-if)#sw m t
Switch(config-if)#sw t a vlan 30,40,50
```

### Kuronexus Public Router
```
Router(config)#interface GigabitEthernet0/1.30
Router(config-subif)#encapsulation dot1Q 30
Router(config-subif)#ip address 192.168.30.1 255.255.255.0
Router(config-subif)#ip helper-address 192.168.12.4
Router(config)#interface GigabitEthernet0/1.40
Router(config-subif)#encapsulation dot1Q 40
Router(config-subif)#ip address 192.168.40.1 255.255.255.0
Router(config-subif)#ip helper-address 192.168.12.4
Router(config)#interface GigabitEthernet0/1.50
Router(config-subif)#encapsulation dot1Q 50
Router(config-subif)#ip address 192.168.50.1 255.255.255.0
Router(config-subif)#ip helper-address 192.168.12.4
```