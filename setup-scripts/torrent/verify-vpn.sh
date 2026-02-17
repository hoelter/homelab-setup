#!/bin/bash
# Verify that the torrent container VPN connection is working correctly.
# Run from the incus host, or remotely via: ssh incus-host "bash -s" < verify-vpn.sh

set -euo pipefail

CONTAINER="torrent"
PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }

echo "=== Torrent VPN Verification ==="
echo ""

# 1. Check all Docker containers are running and healthy
echo "-- Docker Containers --"
for svc in gluetun qbittorrent port-manager; do
    status=$(incus exec "$CONTAINER" -- docker inspect --format '{{.State.Status}}' "$svc" 2>/dev/null || echo "missing")
    health=$(incus exec "$CONTAINER" -- docker inspect --format '{{.State.Health.Status}}' "$svc" 2>/dev/null || echo "unknown")
    if [ "$status" = "running" ] && [ "$health" = "healthy" ]; then
        pass "$svc: running (healthy)"
    elif [ "$status" = "running" ]; then
        warn "$svc: running but health=$health"
    else
        fail "$svc: status=$status health=$health"
    fi
done
echo ""

# 2. Check gluetun VPN status via control server
echo "-- VPN Status --"
vpn_status=$(incus exec "$CONTAINER" -- docker exec gluetun wget -qO- http://localhost:8000/v1/vpn/status 2>/dev/null || echo "{}")
if echo "$vpn_status" | grep -q '"running"'; then
    pass "Gluetun VPN status: running"
else
    fail "Gluetun VPN status: $vpn_status"
fi

# 3. Check VPN IP differs from host IP
vpn_info=$(incus exec "$CONTAINER" -- docker exec gluetun wget -qO- http://localhost:8000/v1/publicip/ip 2>/dev/null || echo "{}")
vpn_ip=$(echo "$vpn_info" | grep -o '"public_ip":"[^"]*"' | cut -d'"' -f4)
vpn_country=$(echo "$vpn_info" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)

host_ip=$(curl -s --max-time 5 https://ipinfo.io/ip 2>/dev/null || echo "unknown")

if [ -n "$vpn_ip" ] && [ "$vpn_ip" != "$host_ip" ]; then
    pass "VPN IP ($vpn_ip, $vpn_country) differs from host IP ($host_ip)"
elif [ -z "$vpn_ip" ]; then
    fail "Could not retrieve VPN IP"
elif [ "$vpn_ip" = "$host_ip" ]; then
    fail "VPN IP matches host IP ($host_ip) — VPN may be leaking!"
fi

# 4. Check DNS is going through VPN (not leaking)
dns_test=$(incus exec "$CONTAINER" -- docker exec gluetun sh -c "nslookup example.com >/dev/null 2>&1 && echo ok" || echo "failed")
if [ "$dns_test" = "ok" ]; then
    pass "DNS resolution working through VPN"
else
    warn "DNS resolution test failed (nslookup may not be available)"
fi
echo ""

# 5. Check port forwarding
echo "-- Port Forwarding --"
forwarded_port=$(incus exec "$CONTAINER" -- cat /home/torrentuser/config/gluetun/forwarded_port 2>/dev/null | tr -d '\n\r')
if [ -n "$forwarded_port" ] && [ "$forwarded_port" -gt 0 ] 2>/dev/null; then
    pass "Forwarded port: $forwarded_port"
else
    fail "No forwarded port found"
fi

# Check qBittorrent is using the forwarded port
qb_port=$(incus exec "$CONTAINER" -- docker exec gluetun wget -qO- http://localhost:8080/api/v2/app/preferences 2>/dev/null | grep -o '"listen_port":[0-9]*' | cut -d: -f2)
if [ -n "$qb_port" ] && [ "$qb_port" = "$forwarded_port" ]; then
    pass "qBittorrent listen port matches forwarded port ($qb_port)"
elif [ -n "$qb_port" ]; then
    warn "qBittorrent port ($qb_port) does not match forwarded port ($forwarded_port)"
else
    warn "Could not query qBittorrent port (may need authentication)"
fi
echo ""

# 6. Verify qBittorrent cannot bypass VPN (killswitch test)
echo "-- Killswitch --"
# qBittorrent uses gluetun's network stack, so test that gluetun's firewall blocks non-VPN traffic
# by checking that the container's network mode is set to service:gluetun
qb_network=$(incus exec "$CONTAINER" -- docker inspect --format '{{.HostConfig.NetworkMode}}' qbittorrent 2>/dev/null || echo "unknown")
if echo "$qb_network" | grep -q "^container:"; then
    # Docker may store the full container ID instead of the name — resolve it
    gluetun_id=$(incus exec "$CONTAINER" -- docker inspect --format '{{.Id}}' gluetun 2>/dev/null || echo "")
    network_target=$(echo "$qb_network" | sed 's/^container://')
    if [ "$network_target" = "gluetun" ] || [ "$network_target" = "$gluetun_id" ]; then
        pass "qBittorrent network routed through gluetun"
    else
        fail "qBittorrent shares network with unknown container: $network_target"
    fi
else
    fail "qBittorrent network mode: $qb_network (expected container:gluetun)"
fi
echo ""

# Summary
echo "=== Summary ==="
echo "  Passed: $PASS  |  Failed: $FAIL  |  Warnings: $WARN"
if [ "$FAIL" -gt 0 ]; then
    echo "  STATUS: PROBLEMS DETECTED"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo "  STATUS: OK (with warnings)"
    exit 0
else
    echo "  STATUS: ALL GOOD"
    exit 0
fi
