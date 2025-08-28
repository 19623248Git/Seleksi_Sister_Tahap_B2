# SSH & Telnet

### Gokouloryn Border Router
```
Router(config)#hostname Gokouloryn_Border
Gokouloryn_Border(config)#ip domain-name border.gk
Gokouloryn_Border(config)#username admin secret adminssh
Gokouloryn_Border(config)#crypto key generate rsa 

How many bits in the modulus [512]: 1024

# SSH Configuration
Gokouloryn_Border(config)#line vty 0 4
Gokouloryn_Border(config-line)#login local
Gokouloryn_Border(config-line)#transport input ssh

# Telnet Configuration
Gokouloryn_Border(config)#line vty 5 8
Gokouloryn_Border(config-line)#password admintelnet
Gokouloryn_Border(config-line)#transport input telnet
Gokouloryn_Border(config-line)#login
```

### Rurinthia Border Router
```
Router(config)#hostname Rurinthia_Border
Rurinthia_Border(config)#ip domain-name border.rr
Rurinthia_Border(config)#username admin secret adminssh1
Rurinthia_Border(config)#crypto key generate rsa 

How many bits in the modulus [512]: 1024

# SSH Configuration
Rurinthia_Border(config)#line vty 0 4
Rurinthia_Border(config-line)#login local
Rurinthia_Border(config-line)#transport input ssh

# Telnet Configuration
Rurinthia_Border(config)#line vty 5 8
Rurinthia_Border(config-line)#password admintelnet1
Rurinthia_Border(config-line)#transport input telnet
Rurinthia_Border(config-line)#login
```


### Kuronexus Border Router
```
Router(config)#hostname Kuronexus_Border
Kuronexus_Border(config)#ip domain-name border.kr
Kuronexus_Border(config)#username admin secret adminssh2
Kuronexus_Border(config)#crypto key generate rsa 

How many bits in the modulus [512]: 1024

# SSH Configuration
Kuronexus_Border(config)#line vty 0 4
Kuronexus_Border(config-line)#login local
Kuronexus_Border(config-line)#transport input ssh

# Telnet Configuration
Kuronexus_Border(config)#line vty 5 8
Kuronexus_Border(config-line)#password admintelnet2
Kuronexus_Border(config-line)#transport input telnet
Kuronexus_Border(config-line)#login
```

### Yamindralia Border Router
```
Router(config)#hostname Yamindralia_Border
Yamindralia_Border(config)#ip domain-name border.ym
Yamindralia_Border(config)#username admin secret adminssh3
Yamindralia_Border(config)#crypto key generate rsa 

How many bits in the modulus [512]: 1024

# SSH Configuration
Yamindralia_Border(config)#line vty 0 4
Yamindralia_Border(config-line)#login local
Yamindralia_Border(config-line)#transport input ssh

# Telnet Configuration
Yamindralia_Border(config)#line vty 5 8
Yamindralia_Border(config-line)#password admintelnet3
Yamindralia_Border(config-line)#transport input telnet
Yamindralia_Border(config-line)#login
```

## Note: Add DNS Records Accordingly

### To Access Gokouloryn Border Router
```
telnet border.gk
# password: admintelnet 

# or
ssh -l admin border.gk
# password: adminssh
```

### To Access Rurinthia Border Router
```
telnet border.rr
# password: admintelnet1 

# or
ssh -l admin border.rr
# password: adminssh1
```

### To Access Kuronexus Border Router
```
telnet border.kr
# password: admintelnet2 

# or
ssh -l admin border.kr
# password: adminssh2
```

### To Access Yamindralia Border Router
```
telnet border.ym
# password: admintelnet3 

# or
ssh -l admin border.ym
# password: adminssh3
```
