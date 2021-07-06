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

## Usage

Run a `git clone` on this repo.

`cd ./terraform-vault-aci`

`terraform init`

`terraform plan -out=tfplan`

`terraform apply tfplan`

In the current module directory hidden folder `.vault` will be spawned.
Vault configuration can be found there.

Terraform will output the FQDN to reach Vault UI, if you do not see it run `terraform output fqdn`

To use Vault CLI (Requires Vault to be installed locally) you need to set 2 environment variables:

`$env:VAULT_ADDR = "http://$(terraform output fqdn)`

`$env:VAULT_SKIP_VERIFY = $true`

Now you can do `vault login` to the new instance (token can be found in `./.vault/config`)
