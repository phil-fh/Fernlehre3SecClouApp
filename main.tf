module "podtatohead-1" {
  source = "./modules/podtatohead"
  podtato_name = "Kunde1"
  hats_version = "v1"
  left_arm_version = "v1"
  left_leg_version = "v1"
  podtato_version = "v0.1.0"
  right_arm_version = "v1"
  right_leg_version = "v1"
}
output "first-url" {
  value = module.podtatohead-1.podtato-url
}
