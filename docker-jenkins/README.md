# docker-jenkins 

## prerequisite
```bash
# update .docker config to use aws credentials for push docker images
echo "{\"credsStore\": \"ecr-login\"}" > ~/.docker/config.json
# login to aws sso
aws sso login
# devops profile should be defined in ~/.aws/config
# [profile devops]
# sso_account_id = 238809347283
# sso_role_name = AWSAdministratorAccess
# sso_start_url = https://purplegroup.awsapps.com/start#/
# sso_region = eu-west-1
# region = af-south-1
# output = json
# set aws profile
export AWS_PROFILE=devops
```

## identify latest tag
```bash
aws ecr describe-images \
  --repository-name devops/jenkins \
  --registry-id 238809347283 \
  --region af-south-1 \
  --query 'sort_by(imageDetails, &imagePushedAt)[-1].imageTags[0]' \
  --output text
# update the tag in docker-compose.yaml
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->