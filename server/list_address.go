package server

import (
	"net"
)

// listAddresses returns the IP addresses of the network interfaces that
// clients on other machines can use to reach the server.
// Loopback and link-local addresses are skipped because they are not
// reachable from other hosts (e.g. from the host OS of a virtual machine).
func listAddresses() (addresses []string) {
	ifaces, err := net.Interfaces()
	if err != nil {
		return []string{}
	}

	addresses = make([]string, 0, len(ifaces))

	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 {
			continue
		}
		ifAddrs, _ := iface.Addrs()
		for _, ifAddr := range ifAddrs {
			var ip net.IP
			switch v := ifAddr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			if ip == nil || ip.IsLoopback() || ip.IsLinkLocalUnicast() {
				continue
			}
			addresses = append(addresses, ip.String())
		}
	}

	return addresses
}

// isWildcardAddress reports whether address makes the server listen on all
// network interfaces.
func isWildcardAddress(address string) bool {
	if address == "" {
		return true
	}
	ip := net.ParseIP(address)
	return ip != nil && ip.IsUnspecified()
}

// buildURL returns a URL for the given host, port and path.
// IPv6 hosts are enclosed in square brackets.
func buildURL(scheme, host, port, path string) string {
	return scheme + "://" + net.JoinHostPort(host, port) + path
}
