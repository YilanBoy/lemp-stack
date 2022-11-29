# Use Terraform to Build LEMP Stack in AWS

Using terraform to build LEMP stack, you will create these resources

- VPC
- public subnet
- private subnet
- app instance
- database instance
- redis instance
- NAT instance

> **Note**
>
> You must set AWS credentials with suitable permission, you can use aws-cli to set this
>

After clone the project, you need change directory into project folder

```bash
cd lemp
```

Initial the terraform project and install provider

```bash
terraform init
```

Use terraform to deploy the resource

```bash
terraform apply
```

After review the deployment plan, you can press `yes` to start to deploy

## Reference

- [VPC with public and private subnets (NAT)](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html)