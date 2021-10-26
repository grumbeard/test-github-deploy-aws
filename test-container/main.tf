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

resource "aws_ecs_service" "worker" {
  name            = "worker-test-1"
  cluster         = aws_ecs_cluster.app-service-cluster.id
  task_definition = aws_ecs_task_definition.api-service.arn
  desired_count   = 2
}

# Creates a few ECS-optimized EC2 instances to be used by cluster
data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "aws_ami" "ecs_optimized_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*amazon-ecs-optimized*"]
  }
}

resource "aws_instance" "ecs_optimized_ec2" {
  for_each      = toset(data.aws_subnets.default_subnets.ids)
  ami           = data.aws_ami.ecs_optimized_ami.id
  instance_type = "t2.micro"
  subnet_id     = each.value
}
