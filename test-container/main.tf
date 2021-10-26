resource "aws_ecr_repository" "api-service-registry" {
  name = "devtools-test-1"
  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecs_cluster" "app-service-cluster" {
  name = "app-service-cluster-test-1"
}

# Creates Task Definition with placeholder image
# Image will be inserted in Task Definition by CI
resource "aws_ecs_task_definition" "api-service" {
  family = "api-service-test-1"
  container_definitions = jsonencode([{
    "name" : "api-service-container-test-1",
    "image" : "scratch",
    "memory" : 512,
    "portMappings" : [
      {
        "containerPort" : 22,
        "hostPort" : 22
        "protocol" : "tcp"
      }
    ]
  }])
  requires_compatibilities = ["EC2"]
}
