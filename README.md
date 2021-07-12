# aws-ukca
Ansible playbook for running UKCA on an AWS EC2 instance

Based on instructions from [Dave Sugden (April 2020)](https://davelms.medium.com/use-ansible-to-create-and-configure-ec2-instances-on-aws-cfbb0ed019bf) and [Vivek Gite (February 2018)](https://www.cyberciti.biz/faq/how-to-create-aws-ec2-key-using-ansible/)

Tested on macOS 10.13.6

Before you start, install the [AWS CLI](https://aws.amazon.com/cli/) and run the 
```
aws configure
```
to set your IAM's `aws_access_key_id`, `aws_secret_access_key`, and default `region`. These are put in the `~/.aws/credentials` and `~/.aws/config` files.

EC2 variables are set in `roles/create-ec2-instances/vars/main.yml`.