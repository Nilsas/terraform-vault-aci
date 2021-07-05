# Terraform for Vault on Azure Container Instances

Vault is ran in `server` configuration rathen than `dev` this makes for
a better way of having a playground than running a `dev` server which only stores data in memory.

This `terraform` code deploys:

- Storage Account
- Storage Share for Configuration
- Storage Share for Data
- Azure Container Instance (with latest official Vault container)

Feel free to grab this and modify to your liking, also please raise an issue if you encounter any issues.

Tested with:

- Terraform version `v1.0.1`
- AzureRM provider version `2.66.0`
