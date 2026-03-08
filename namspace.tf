resource "kubernetes_namespace" "retail" {
  metadata {
    name = "retail-app"
  }
}
