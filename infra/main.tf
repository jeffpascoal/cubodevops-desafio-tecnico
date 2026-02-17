resource "docker_network" "public_net" {
  name = "${var.project_name}_public"
}

resource "docker_network" "private_net" {
  name     = "${var.project_name}_private"
  internal = true
}

resource "docker_volume" "pgdata" {
  name = "${var.project_name}_pgdata"
}

resource "docker_image" "backend" {
  name = "${var.project_name}-backend:1.0.0"
  build { context = "${path.module}/../backend" }
}

resource "docker_image" "frontend" {
  name = "${var.project_name}-frontend:1.0.0"
  build { context = "${path.module}/../frontend" }
}

resource "docker_container" "db" {
  name    = "${var.project_name}-db"
  image   = "postgres:15.8"
  restart = "always"

  networks_advanced {
    name    = docker_network.private_net.name
    aliases = ["db"]
  }

  env = [
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
  ]

  mounts {
    type   = "volume"
    target = "/var/lib/postgresql/data"
    source = docker_volume.pgdata.name
  }

  mounts {
    type      = "bind"
    target    = "/docker-entrypoint-initdb.d/script.sql"
    source    = abspath("${path.module}/../sql/script.sql")
    read_only = true
  }

  # (Optional but recommended) avoids startup flakiness
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.postgres_user} -d ${var.postgres_db} -h 127.0.0.1 -p 5432 || exit 1"]
    interval = "5s"
    timeout  = "3s"
    retries  = 20
  }
}

resource "docker_container" "backend" {
  name    = "${var.project_name}-backend"
  image   = docker_image.backend.name
  restart = "always"

  networks_advanced {
    name    = docker_network.private_net.name
    aliases = ["backend"]
  }

  env = [
    "PORT=3000",
    "DB_HOST=db",
    "DB_PORT=5432",
    "DB_NAME=${var.postgres_db}",
    "DB_USER=${var.postgres_user}",
    "DB_PASSWORD=${var.postgres_password}",
  ]

  depends_on = [docker_container.db]
}

resource "docker_container" "frontend" {
  name    = "${var.project_name}-frontend"
  image   = docker_image.frontend.name
  restart = "always"

  networks_advanced {
    name    = docker_network.public_net.name
    aliases = ["frontend"]
  }
}

resource "docker_container" "proxy" {
  name    = "${var.project_name}-proxy"
  image   = "nginx:1.27-alpine"
  restart = "always"

  ports {
    internal = 80
    external = var.proxy_port
  }

  networks_advanced {
    name    = docker_network.public_net.name
    aliases = ["proxy"]
  }

  networks_advanced {
    name    = docker_network.private_net.name
    aliases = ["proxy"]
  }

  mounts {
    type      = "bind"
    target    = "/etc/nginx/conf.d/default.conf"
    source    = abspath("${path.module}/../proxy/nginx.conf")
    read_only = true
  }

  depends_on = [docker_container.backend, docker_container.frontend]
}

resource "docker_container" "cadvisor" {
  name    = "${var.project_name}-cadvisor"
  image   = "gcr.io/cadvisor/cadvisor:latest"
  restart = "always"

  ports {
    internal = 8080
    external = var.cadvisor_port
    ip       = "127.0.0.1"
  }

  networks_advanced {
    name = docker_network.public_net.name
  }

  mounts {
    type      = "bind"
    source    = "/"
    target    = "/rootfs"
    read_only = true
  }

  mounts {
    type   = "bind"
    source = "/var/run"
    target = "/var/run"
  }

  mounts {
    type      = "bind"
    source    = "/sys"
    target    = "/sys"
    read_only = true
  }

  mounts {
    type      = "bind"
    source    = "/var/lib/docker"
    target    = "/var/lib/docker"
    read_only = true
  }
}

