# OSPF

## Gokouloryn

### Gokouloryn Gov Router
```
Router(config)#router ospf 1
Router(config-router)#router-id 1.1.1.1
Router(config-router)#network 192.168.1.0 0.0.0.255 area 0
Router(config-router)#network 192.168.2.0 0.0.0.255 area 1
```

### Gokouloryn Pub Router
```
Router(config)#router ospf 1
Router(config-router)#router-id 1.1.1.2
Router(config-router)#network 192.168.1.0 0.0.0.255 area 0
Router(config-router)#network 192.168.3.0 0.0.0.255 area 2
```

### Gokouloryn Ent Router
```
Router(config)#router ospf 1
Router(config-router)#router-id 1.1.1.3
Router(config-router)#network 192.168.1.0 0.0.0.255 area 0
Router(config-router)#network 192.168.4.0 0.0.0.255 area 3
```

### Gokouloryn Border Router
```
Router(config)#router ospf 1
Router(config-router)#router-id 1.1.1.4
Router(config-router)#network 192.168.1.0 0.0.0.255 area 0
```

## Rurinthia

### Rurinthia Gov Router
```
Router(config)#router ospf 2
Router(config-router)#router-id 2.1.1.1
Router(config-router)#network 192.168.5.0 0.0.0.255 area 0
Router(config-router)#network 192.168.6.0 0.0.0.255 area 1
```

### Rurinthia Pub Router
```
Router(config)#router ospf 2
Router(config-router)#router-id 2.1.1.2
Router(config-router)#network 192.168.5.0 0.0.0.255 area 0
Router(config-router)#network 192.168.7.0 0.0.0.255 area 2
```

### Rurinthia Ent Router
```
Router(config)#router ospf 2
Router(config-router)#router-id 2.1.1.3
Router(config-router)#network 192.168.5.0 0.0.0.255 area 0
Router(config-router)#network 192.168.8.0 0.0.0.255 area 3
```

### Rurinthia Border Router
```
Router(config)#router ospf 2
Router(config-router)#router-id 2.1.1.4
Router(config-router)#network 192.168.5.0 0.0.0.255 area 0
```

## Kuronexus

### Kuronexus Gov Router
```
Router(config)#router ospf 3
Router(config-router)#router-id 3.1.1.1
Router(config-router)#network 192.168.9.0 0.0.0.255 area 0
Router(config-router)#network 192.168.10.0 0.0.0.255 area 1
```

### Kuronexus Pub Router
```
Router(config)#router ospf 3
Router(config-router)#router-id 3.1.1.2
Router(config-router)#network 192.168.9.0 0.0.0.255 area 0
Router(config-router)#network 192.168.30.0 0.0.0.255 area 2
Router(config-router)#network 192.168.40.0 0.0.0.255 area 2
Router(config-router)#network 192.168.50.0 0.0.0.255 area 2
```

### Kuronexus Ent Router
```
Router(config)#router ospf 3
Router(config-router)#router-id 3.1.1.3
Router(config-router)#network 192.168.9.0 0.0.0.255 area 0
Router(config-router)#network 192.168.12.0 0.0.0.255 area 3
```

### Kuronexus Border Router
```
Router(config)#router ospf 3
Router(config-router)#router-id 3.1.1.4
Router(config-router)#network 192.168.9.0 0.0.0.255 area 0
```

## Yamindralia

### Yamindralia Gov Router
```
Router(config)#router ospf 4
Router(config-router)#router-id 4.1.1.1
Router(config-router)#network 192.168.13.0 0.0.0.255 area 0
Router(config-router)#network 192.168.14.0 0.0.0.255 area 1
```

### Yamindralia Pub Router
```
Router(config)#router ospf 4
Router(config-router)#router-id 4.1.1.2
Router(config-router)#network 192.168.13.0 0.0.0.255 area 0
Router(config-router)#network 192.168.15.0 0.0.0.255 area 2
```

### Yamindralia Ent Router
```
Router(config)#router ospf 4
Router(config-router)#router-id 4.1.1.3
Router(config-router)#network 192.168.13.0 0.0.0.255 area 0
Router(config-router)#network 192.168.16.0 0.0.0.255 area 3
```

### Yamindralia Border Router
```
Router(config)#router ospf 4
Router(config-router)#router-id 4.1.1.4
Router(config-router)#network 192.168.13.0 0.0.0.255 area 0
```

#### Check OSPF Neighbors
```
Router#show ip ospf neighbor
```