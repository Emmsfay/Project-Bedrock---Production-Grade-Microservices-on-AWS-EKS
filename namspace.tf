resource "kubernetes_namespace_v1" "retail" {
  metadata {
    name = "retail-app"
  }

  lifecycle {
    ignore_changes = all
  }
}
