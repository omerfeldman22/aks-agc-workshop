locals {
  python_server_files = fileset("${path.cwd}/../../python_server", "**")
  python_server_hash  = md5(join("", [for f in local.python_server_files : filemd5("${path.cwd}/../../python_server/${f}")]))
}

# Build and push python_server image
resource "docker_image" "python_server" {
  name = "${data.azurerm_container_registry.acr.login_server}/python-server:latest"

  build {
    context    = "${path.module}/../../python_server"
    dockerfile = "Dockerfile"
    tag        = ["${data.azurerm_container_registry.acr.login_server}/python-server:latest"]
  }

  triggers = {
    dir_sha1 = local.python_server_hash
  }
}

resource "docker_registry_image" "python_server" {
  name = docker_image.python_server.name

  keep_remotely = true
}