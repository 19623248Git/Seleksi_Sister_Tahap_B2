# BGP

## Gokouloryn

### Gokouloryn Border Router
```
Router(config)#router bgp 20
Router(config-router)#bgp router-id 1.1.1.4
Router(config-router)#neighbor 10.1.1.3 remote-as 30
Router(config-router)#neighbor 10.1.1.4 remote-as 40
Router(config-router)#network 192.168.1.0 mask 255.255.255.0
Router(config-router)#network 192.168.2.0 mask 255.255.255.0
Router(config-router)#network 192.168.3.0 mask 255.255.255.0
Router(config-router)#network 192.168.4.0 mask 255.255.255.0
Router(config-router)#exit
Router(config)#router ospf 1
Router(config-router)#redistribute bgp 20 subnets
```

## Rurinthia

### Rurinthia Border Router
```
Router(config)#router bgp 30
Router(config-router)#bgp router-id 2.1.1.4
Router(config-router)#neighbor 10.1.1.2 remote-as 20
Router(config-router)#neighbor 10.1.1.4 remote-as 40
Router(config-router)#network 192.168.5.0 mask 255.255.255.0
Router(config-router)#network 192.168.6.0 mask 255.255.255.0
Router(config-router)#network 192.168.7.0 mask 255.255.255.0
Router(config-router)#network 192.168.8.0 mask 255.255.255.0
Router(config-router)#exit
Router(config)#router ospf 2
Router(config-router)#redistribute bgp 30 subnets
```

## Kuronexus

### Kuronexus Border Router
```
Router(config)#router bgp 40
Router(config-router)#bgp router-id 3.1.1.4
Router(config-router)#neighbor 10.1.1.2 remote-as 20
Router(config-router)#neighbor 10.1.1.3 remote-as 30
Router(config-router)#neighbor 172.16.0.2 remote-as 50
Router(config-router)#network 192.168.9.0 mask 255.255.255.0
Router(config-router)#network 192.168.10.0 mask 255.255.255.0
Router(config-router)#network 192.168.30.0 mask 255.255.255.0
Router(config-router)#network 192.168.40.0 mask 255.255.255.0
Router(config-router)#network 192.168.50.0 mask 255.255.255.0
Router(config-router)#network 192.168.12.0 mask 255.255.255.0
Router(config-router)#exit
Router(config)#router ospf 3
Router(config-router)#redistribute bgp 40 subnets
```

## Yamindralia

### Yamindralia Border Router
```
Router(config)#router bgp 50
Router(config-router)#bgp router-id 4.1.1.4
Router(config-router)#neighbor 172.16.0.1 remote-as 40
Router(config-router)#network 192.168.13.0 mask 255.255.255.0
Router(config-router)#network 192.168.14.0 mask 255.255.255.0
Router(config-router)#network 192.168.15.0 mask 255.255.255.0
Router(config-router)#network 192.168.16.0 mask 255.255.255.0
Router(config-router)#exit
Router(config)#router ospf 4
Router(config-router)#redistribute bgp 50 subnets
```