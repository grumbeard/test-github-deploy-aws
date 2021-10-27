resource "aws_ecr_repository" "api-service-registry" {
  name = "devtools-test-1"
  encryption_configuration {
    encryption_type = "AES256"
  }
}

# resource "aws_ecs_cluster" "app-service-cluster" {
#   name = "app-service-cluster-test-1"
# }

data "aws_ecs_cluster" "default-cluster" {
  cluster_name = "default"
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
  cluster         = data.aws_ecs_cluster.default-cluster.id
  task_definition = aws_ecs_task_definition.api-service.arn
  desired_count   = 2
}

# Get Subnet IDs of default VPC
data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

# Create IAM Instance profile for ECS Container
data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_container_role" {
  name               = "ecs_container_role-test-1"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json
}

data "aws_iam_policy" "ecs_container_policy_ecs" {
  name = "AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "attach_container_policy_ecs_to_role" {
  role       = aws_iam_role.ecs_container_role.name
  policy_arn = data.aws_iam_policy.ecs_container_policy_ecs.arn
}

data "aws_iam_policy" "ecs_container_policy_s3" {
  name = "AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "attach_container_policy_s3_to_role" {
  role       = aws_iam_role.ecs_container_role.name
  policy_arn = data.aws_iam_policy.ecs_container_policy_s3.arn
}

resource "aws_iam_instance_profile" "ecs_container_iam_profile" {
  name = "ecs_container_iam_profile-test-1"
  role = aws_iam_role.ecs_container_role.name
}

data "aws_ami" "ecs_optimized_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*amazon-ecs-optimized*"]
  }
}

# Creates a few ECS-optimized EC2 instances to be used by cluster as containers
resource "aws_instance" "ecs_optimized_ec2" {
  for_each             = toset(data.aws_subnets.default_subnets.ids)
  ami                  = data.aws_ami.ecs_optimized_ami.id
  instance_type        = "t2.micro"
  subnet_id            = each.value
  iam_instance_profile = aws_iam_instance_profile.ecs_container_iam_profile.name
  tags = {
    "Name" = "ecs-test-${each.value}"
  }
}
