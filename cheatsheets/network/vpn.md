# VPN

> Establish OpenVPN and IPsec connections from the CLI

<!-- tags: vpn, openvpn, ipsec, strongswan, network -->

---

## Connect OpenVPN
Bring up an OpenVPN connection from a config file.

```bash
sudo openvpn {{CONFIG:file:lab.ovpn}}
```

<!-- meta: risk=safe | phase=misc | tags=openvpn,connect,ovpn -->

---

## Connect OpenVPN (Daemonized + Log)
Run OpenVPN in the background and write logs.

```bash
sudo openvpn --config {{CONFIG:file:lab.ovpn}} --daemon --log {{LOG:file:vpn.log}}
```

<!-- meta: risk=safe | phase=misc | tags=openvpn,daemon,log -->

---

## Connect IPsec/IKEv2 (StrongSwan)
Bring up a named StrongSwan connection.

```bash
sudo strongswan up {{CONNECTION:str:lab}}
```

<!-- meta: risk=safe | phase=misc | tags=strongswan,ipsec,up -->

---

## Tear Down IPsec Connection
Disconnect a StrongSwan tunnel.

```bash
sudo strongswan down {{CONNECTION:str:lab}}
```

<!-- meta: risk=safe | phase=misc | tags=strongswan,ipsec,down -->

---

## Show OpenVPN Process Status
Verify the tunnel interface and routes are up.

```bash
ip addr show tun0 && ip route
```

<!-- meta: risk=safe | phase=misc | tags=tun0,routes,status -->
