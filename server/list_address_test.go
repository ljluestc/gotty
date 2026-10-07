package server

import (
	"net"
	"testing"
)

func TestBuildURL(t *testing.T) {
	cases := []struct {
		host, want string
	}{
		{"192.168.56.101", "http://192.168.56.101:8080/"},
		{"localhost", "http://localhost:8080/"},
		{"2001:db8::1", "http://[2001:db8::1]:8080/"},
	}
	for _, c := range cases {
		if got := buildURL("http", c.host, "8080", "/"); got != c.want {
			t.Errorf("buildURL(%q) = %q, want %q", c.host, got, c.want)
		}
	}
}

func TestIsWildcardAddress(t *testing.T) {
	cases := map[string]bool{
		"":          true,
		"0.0.0.0":   true,
		"::":        true,
		"127.0.0.1": false,
		"10.0.0.5":  false,
		"localhost": false,
	}
	for address, want := range cases {
		if got := isWildcardAddress(address); got != want {
			t.Errorf("isWildcardAddress(%q) = %v, want %v", address, got, want)
		}
	}
}

func TestListAddressesSkipsUnreachable(t *testing.T) {
	for _, address := range listAddresses() {
		ip := net.ParseIP(address)
		if ip == nil {
			t.Errorf("listAddresses returned invalid IP %q", address)
			continue
		}
		if ip.IsLoopback() || ip.IsLinkLocalUnicast() {
			t.Errorf("listAddresses returned unreachable address %q", address)
		}
	}
}
