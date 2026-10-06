"""Structural tests to validate the repository layout and configuration files.

These tests run without Docker and validate that the project is correctly
organized for the network security risk mitigation lab.
"""

from pathlib import Path

import yaml

PROJECT_ROOT = Path(__file__).parent.parent
DOCKER_DIR = PROJECT_ROOT / "docker"
SCRIPTS_DIR = PROJECT_ROOT / "scripts"


def test_docker_compose_exists() -> None:
    """docker-compose.yml must exist at project root."""
    assert (PROJECT_ROOT / "docker-compose.yml").is_file()


def test_docker_compose_is_valid_yaml() -> None:
    """docker-compose.yml must be valid YAML."""
    with (PROJECT_ROOT / "docker-compose.yml").open() as f:
        data = yaml.safe_load(f)
    assert "services" in data
    assert "networks" in data


def test_docker_compose_defines_expected_services() -> None:
    """All lab services must be present."""
    with (PROJECT_ROOT / "docker-compose.yml").open() as f:
        data = yaml.safe_load(f)
    services = data["services"]
    for service in ("mysql", "nginx", "api", "redis", "admin"):
        assert service in services, f"Missing service: {service}"


def test_network_segmentation_is_configured() -> None:
    """Frontend and backend networks must exist with the correct subnets."""
    with (PROJECT_ROOT / "docker-compose.yml").open() as f:
        data = yaml.safe_load(f)
    networks = data["networks"]
    assert "frontend" in networks
    assert "backend" in networks
    frontend_subnet = networks["frontend"]["ipam"]["config"][0]["subnet"]
    backend_subnet = networks["backend"]["ipam"]["config"][0]["subnet"]
    assert frontend_subnet == "172.20.0.0/16"
    assert backend_subnet == "172.21.0.0/16"


def test_admin_is_only_on_frontend() -> None:
    """Admin container must not have access to backend network."""
    with (PROJECT_ROOT / "docker-compose.yml").open() as f:
        data = yaml.safe_load(f)
    admin_networks = data["services"]["admin"]["networks"]
    assert "frontend" in admin_networks
    assert "backend" not in admin_networks


def test_mysql_and_redis_are_backend_only() -> None:
    """Backend services must not be on the frontend network."""
    with (PROJECT_ROOT / "docker-compose.yml").open() as f:
        data = yaml.safe_load(f)
    for service in ("mysql", "redis"):
        networks = data["services"][service]["networks"]
        assert "backend" in networks
        assert "frontend" not in networks


def test_nginx_conf_has_tls_directives() -> None:
    """Nginx config must enable TLS on port 443."""
    nginx_conf = (DOCKER_DIR / "nginx" / "nginx.conf").read_text()
    assert "listen 443 ssl" in nginx_conf
    assert "ssl_certificate" in nginx_conf
    assert "ssl_certificate_key" in nginx_conf
    assert "TLSv1.2" in nginx_conf
    assert "TLSv1.3" in nginx_conf


def test_scripts_are_executable() -> None:
    """All scripts in scripts/ must be executable."""
    for script in SCRIPTS_DIR.glob("*.sh"):
        assert script.stat().st_mode & 0o111, f"{script.name} is not executable"


def test_required_scripts_exist() -> None:
    """Required scripts must be present."""
    for script_name in ("scan.sh", "validate.sh", "firewall.sh"):
        assert (SCRIPTS_DIR / script_name).is_file(), f"Missing script: {script_name}"


def test_env_example_exists() -> None:
    """.env.example must exist for reference."""
    assert (PROJECT_ROOT / ".env.example").is_file()


def test_license_is_mit() -> None:
    """LICENSE must be the MIT license."""
    license_text = (PROJECT_ROOT / "LICENSE").read_text()
    assert "MIT License" in license_text
    assert "Diego Alejandro Botina" in license_text