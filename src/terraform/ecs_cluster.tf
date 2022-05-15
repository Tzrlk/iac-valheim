# Sets up the fargate-driven ECS cluster itself.

resource "aws_ecs_cluster" "Valheim" {
	name = "valheim"
	tags = {
		Cost = "Free"
	}
}

variable "Sketchy" {
	description = "Whether or not to schedule on Fargate Spot and take the risk of a shutdown."
	type        = bool
	default     = true
}
resource "aws_ecs_cluster_capacity_providers" "FargateSpot" {
	cluster_name       = aws_ecs_cluster.Valheim.name
	capacity_providers = [ var.Sketchy ? "FARGATE_SPOT" : "FARGATE" ]
}
