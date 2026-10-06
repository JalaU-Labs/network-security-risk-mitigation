# Manual Installation of Security Testing Tools

This document describes how to install the security testing tools used in this
laboratory directly on a host system. The recommended approach is to use the
provided Docker environment, which already includes all required tools in the
`admin` container (`nicolaka/netshoot`). Use these instructions only if you
need to run the tools outside Docker.

## Tools Covered

- **Nmap** - Network exploration and port scanning.
- **Netcat (nc)** - TCP/UDP connectivity testing.
- **curl** - HTTP/HTTPS client for validating web services.
- **tcpdump** - Network traffic inspection.
- **OpenSSL** - TLS certificate generation and inspection.

## Arch Linux

```bash
sudo pacman -S nmap openbsd-netcat curl tcpdump openssl
```

## Debian / Ubuntu

```bash
sudo apt update
sudo apt install -y nmap netcat-openbsd curl tcpdump openssl
```

## Fedora / RHEL

```bash
sudo dnf install -y nmap nc curl tcpdump openssl
```

## macOS (Homebrew)

```bash
brew install nmap netcat curl tcpdump openssl
```

## Windows

Use WSL2 with one of the Linux distributions above. Native Windows ports of
these tools exist but are not recommended for this laboratory.

## Docker Alternative (Recommended)

All tools are available in the `admin` container. Start the environment with:

```bash
make up
docker exec -it admin bash
```

Inside the container, run:

```bash
nmap -sV nginx
nmap -p 3306 mysql
nmap -p 6379 redis
nc -vz api 80
nc -vz redis 6379
curl -vk https://nginx --insecure
tcpdump -i eth0
```

This approach guarantees a reproducible environment and avoids polluting the
host system with additional packages.