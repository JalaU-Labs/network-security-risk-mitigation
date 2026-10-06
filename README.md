# Network Security Risk Mitigation

Laboratory Week 6 - Computer Networks 2 - Jala University

## Objective

Analyze common vulnerabilities in a network infrastructure and apply basic
protection, segmentation, and assurance mechanisms using controlled Docker
environments, in order to understand real-world risks and security best
practices.

This laboratory covers two activities:

1. **Activity 1 - Reconnaissance and Vulnerability Analysis:** Identify exposed
   services and potential security risks using Nmap and Netcat in a controlled
   Docker environment.

2. **Activity 2 - Mitigation and Network Protection:** Implement network
   segmentation, apply firewall controls, enable HTTPS with TLS, and validate
   the reduction of the attack surface.

## General Architecture

The environment simulates a small production stack composed of the following
services, all managed by Docker Compose:

| Service | Image | Role | Network |
|---|---|---|---|
| `mysql` | mysql:8 | Relational database | backend |
| `redis` | redis:7 | In-memory cache | backend |
| `api` | Custom (FastAPI) | REST API | frontend + backend |
| `nginx` | Custom (nginx:latest) | Reverse proxy with TLS | frontend |
| `admin` | nicolaka/netshoot | Reconnaissance container | frontend |

### Network Segmentation

Two isolated bridge networks are defined with explicit subnets:

- **frontend** (`172.20.0.0/16`): Nginx, API, admin.
- **backend** (`172.21.0.0/16`): MySQL, Redis, API.

The `admin` container is intentionally excluded from the `backend` network so
that it cannot reach MySQL or Redis directly. This segmentation is the primary
mitigation mechanism: Docker's embedded DNS prevents `admin` from resolving
`mysql` and `redis`, effectively blocking lateral movement.

### TLS Configuration

Nginx is configured to serve HTTPS on port 443 using a self-signed certificate,
and redirects HTTP traffic from port 80 to HTTPS. TLS 1.2 and TLS 1.3 are
enabled; weaker protocols and ciphers are disabled.

## Project Structure

```
.
├── .docs/                          # Additional documentation
├── .github/workflows/ci.yml        # GitHub Actions pipeline
├── .gitlab-ci.yml                  # GitLab CI pipeline
├── .editorconfig                   # Editor configuration
├── .env.example                    # Example environment variables
├── .gitignore
├── .yamllint.yml                   # Yamllint configuration
├── CONTRIBUTING.md                 # Contribution guidelines
├── LICENSE                         # MIT License
├── Makefile                        # Common tasks
├── README.md
├── docker-compose.yml              # Service orchestration
├── docker/
│   ├── api/
│   │   ├── Dockerfile
│   │   └── main.py                 # FastAPI application
│   └── nginx/
│       ├── Dockerfile
│       └── nginx.conf              # Nginx configuration with TLS
├── pyproject.toml                  # Python project metadata
├── ruff.toml                       # Ruff linter configuration
├── scripts/
│   ├── firewall.sh                 # Example iptables rule
│   ├── scan.sh                     # Automated reconnaissance
│   └── validate.sh                 # Post-mitigation validation
├── src/
│   └── network_security_risk_mitigation/
│       └── __init__.py
├── tests/
│   └── test_project_structure.py   # Structural test suite
└── uv.lock                         # Locked dependency versions
```

## Prerequisites

The following tools are required on the host machine:

- Docker Engine 24 or later
- Docker Compose v2
- Python 3.14 or later
- `uv` 0.12.23 or later

## Setup

Clone the repository and install Python dependencies:

```bash
git clone <repository-url>
cd network-security-risk-mitigation
make setup
```

`make setup` runs `uv sync`, which creates a virtual environment and installs
all development dependencies.

## Usage

The `Makefile` exposes the following targets:

| Target | Description |
|---|---|
| `make setup` | Install Python dependencies using `uv` |
| `make up` | Start all Docker services in detached mode |
| `make down` | Stop and remove all Docker services |
| `make scan` | Run the reconnaissance script (Nmap + Netcat) |
| `make validate` | Run the post-mitigation validation script |
| `make test` | Execute the Pytest suite |
| `make lint` | Run Ruff and Yamllint |
| `make format` | Auto-format Python code with Ruff |
| `make clean` | Remove containers, volumes, virtual environment, and logs |

### Manual TLS Certificate Generation

The Nginx container requires a TLS certificate. A self-signed certificate can
be generated locally with:

```bash
mkdir -p docker/nginx/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout docker/nginx/certs/key.pem \
  -out docker/nginx/certs/cert.pem \
  -subj "/CN=localhost"
```

The `docker/nginx/certs/` directory is excluded from version control to avoid
committing private keys. In CI, dummy certificates are generated on the fly.

## Tests and Results

### Structural Test Suite

The test suite validates the repository layout and configuration without
requiring Docker. It is located at `tests/test_project_structure.py` and
contains 11 tests:

```
tests/test_project_structure.py::test_docker_compose_exists PASSED
tests/test_project_structure.py::test_docker_compose_is_valid_yaml PASSED
tests/test_project_structure.py::test_docker_compose_defines_expected_services PASSED
tests/test_project_structure.py::test_network_segmentation_is_configured PASSED
tests/test_project_structure.py::test_admin_is_only_on_frontend PASSED
tests/test_project_structure.py::test_mysql_and_redis_are_backend_only PASSED
tests/test_project_structure.py::test_nginx_conf_has_tls_directives PASSED
tests/test_project_structure.py::test_scripts_are_executable PASSED
tests/test_project_structure.py::test_required_scripts_exist PASSED
tests/test_project_structure.py::test_env_example_exists PASSED
tests/test_project_structure.py::test_license_is_mit PASSED

11 passed in 0.04s
```

### Activity 1 - Reconnaissance Results

Before applying mitigations, all services were reachable from the `admin`
container on a single bridge network (`lab6-net`).

| Service | Port | State | Version detected |
|---|---|---|---|
| nginx | 80 | open | nginx 1.31.6 |
| mysql | 3306 | open | mysql |
| redis | 6379 | open | redis |
| api | 80 | open | FastAPI |

### Activity 2 - Validation Results

After applying network segmentation and enabling TLS, the following results
were observed from the `admin` container:

```
--- Attempt to reach MySQL (should fail) ---
nc: getaddrinfo for host "mysql" port 3306: Name does not resolve
BLOCKED as expected

--- Attempt to reach Redis (should fail) ---
nc: getaddrinfo for host "redis" port 6379: Name does not resolve
BLOCKED as expected

--- Attempt to reach API (should succeed) ---
Connection to api (172.20.0.3) 80 port [tcp/http] succeeded!

--- Verify HTTPS is active ---
HTTP status: 200
```

Nmap scan from `admin` after mitigation:

```
PORT    STATE SERVICE  VERSION
80/tcp  open  http     nginx 1.31.6
443/tcp open  ssl/http nginx 1.31.6
```

MySQL and Redis are no longer reachable from the `admin` container.

### Before vs After Comparison

| Aspect | Before mitigation | After mitigation |
|---|---|---|
| MySQL from admin | Reachable (port 3306) | Not resolvable |
| Redis from admin | Reachable (port 6379) | Not resolvable |
| API from admin | Reachable (port 80) | Reachable (expected) |
| Nginx protocol | HTTP only | HTTP redirects to HTTPS |
| TLS version | None | TLS 1.2 / TLS 1.3 |
| Network topology | Single bridge | frontend + backend |

## Continuous Integration

Two CI pipelines are configured to validate every push and pull request:

- **GitHub Actions:** `.github/workflows/ci.yml`
- **GitLab CI:** `.gitlab-ci.yml`

Both pipelines execute three stages in sequence:

1. **Lint:** Ruff (Python) and Yamllint (YAML).
2. **Test:** Pytest with coverage report.
3. **Build:** Docker image builds for the API and Nginx services.

## Security Findings and Mitigations

| Risk | Impact | Mitigation applied |
|---|---|---|
| Database exposed on the network | Brute force, SQL injection, data exfiltration | Network segmentation (backend only) |
| Cache exposed without authentication | Remote code execution, data leakage | Network segmentation (backend only) |
| Plaintext HTTP traffic | Credential interception, MITM | HTTPS with TLS 1.2/1.3 |
| Service version disclosure | Targeted CVE exploitation | Reduced external exposure; version disclosure remains on Nginx (documented limitation) |
| API without authentication | Unauthorized access | Restrict to frontend; authentication is out of scope for this lab |

## Reflection

1. **Why is reconnaissance a critical phase for both attackers and defenders?**
   It maps the attack surface. Attackers use it to identify exploitable
   services; defenders use it to detect unintended exposures before attackers
   do.

2. **Which services represent the highest risk when exposed?**
   Backend services such as MySQL and Redis. They have no built-in transport
   security, Redis ships without authentication by default, and both allow
   lateral movement if reached.

3. **How does a firewall reduce the attack surface?**
   It filters traffic by port, protocol, or origin, denying access to services
   that should not be publicly reachable. In Docker, network segmentation
   achieves an equivalent effect at the network layer.

4. **Why is HTTPS essential in modern networks?**
   It provides confidentiality and integrity through TLS, preventing
   eavesdropping and man-in-the-middle attacks. Modern browsers and standards
   require it.

5. **What advantages does Docker offer for controlled security testing?**
   Isolation, reproducibility, and disposability. Environments can be
   destroyed and recreated identically, and risky services never touch the
   host network.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for
details.

## Author

Diego Alejandro Botina
Jala University - Computer Networks 2