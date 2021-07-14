# aws-ukca

Ansible playbook for running UKCA on an AWS EC2 instance. This is based on the Vagrant-based [Met Office Virtual Machine](https://github.com/metomi/metomi-vms) and previous work on using Ansible for this VM on the [JASMIN Unmanaged Cloud](https://github.com/theabro/ukca-playbook). 

Based on instructions from [Dave Sugden (April 2020)](https://davelms.medium.com/use-ansible-to-create-and-configure-ec2-instances-on-aws-cfbb0ed019bf) and [Vivek Gite (February 2018)](https://www.cyberciti.biz/faq/how-to-create-aws-ec2-key-using-ansible/), as well as general Googling.

Tested on macOS 10.13.6. On macOS you may first need to

	export PATH="/Users/[YOUR USERNAME]/Library/Python/2.7/bin:$PATH"

Before you start, install the [AWS CLI](https://aws.amazon.com/cli/) and run the 

	aws configure

to set your IAM's `aws_access_key_id`, `aws_secret_access_key`, and default `region`. These are put in the `~/.aws/credentials` and `~/.aws/config` files.

This is a 2 stage process:

1. Create the EC2 instance.
2. Provision the EC2 instance with the required packages and settings to run FCM, Rose, & Cylc and prepare it for UM-UKCA use. 

## Create the EC2 instance

Change any settings as required to the EC2 variables that are set in `roles/create-ec2-instances/vars/main.yml` file. The volume size has been set here to 30GB, and the instance type is currently `t2.micro` (the _"free tier"_ size). Other [instance types](https://aws.amazon.com/ec2/instance-types/) are available. This can be resized by [following the instructions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-resize.html) for changing the instance using the AWS console.

You should rename the file `inventory/ec2.example` to `inventory/ec2`. This file will contain a list of EC2 instances when they have been created.

Run the command

	ansible-playbook -v create-ec2.yml -i inventory

to create the EC2 instance. When this has completed the VM that has been created will be listed in the `inventory/ec2` file.

## Managing the EC2 instance

You should use the [AWS console](https://aws.amazon.com/) to manage the EC2 instance, specifically the **EC2** Dashboard which can be found under _All services_. 

If the VM becomes unresponsive you many need to force-stop it via the EC2 Dashboard. 

The EC2 instance is created with 30GB of Elastic Block Store (EBS) disk for the filesystem. When you terminate the EC2 instance in the EC2 Dashboard you will need to separately delete the storage under **EBS - Volumes**.

## Provision the Met Office VM

Once the EC2 instance has been created, you can provision the Met Office VM on it by running the command

	ansible-playbook -v provision.yml -i inventory

This will take the information of the EC2 instance created from the file `inventory/ec2`. If you terminate this instance or if its IP address changes you will need to update this file.

It will take some time to provision this VM, due to the number of packages that are installed and the other options made. 

The Ansible playbook goes further than the original [Met Office Virtual Machine](https://github.com/metomi/metomi-vms) in that it also performs the equivalent commands to

	sudo install-um-extras -v 11.2

(and later UM versions), as well as the 

	install-iris

command. It also downloads and installs [xconv1.94](http://cms.ncas.ac.uk/documents/xconv/) into `$UMDIR/bin`. 

Additional connectivity is provided through the use of [X2Go](https://wiki.x2go.org/) to provide a graphical login to the VM. 

### Using X2Go Client

Before you can connect to the VM you may need to install X2Go client.

* [https://wiki.x2go.org/doku.php/download:start](https://wiki.x2go.org/doku.php/download:start)

1. Fill out the settings details on new session popup as below.

2. Click on your new session on the right hand side of the x2goclient window.

3. It should automatically login, asking if you wish to allow connection on first run.

The advantage of using X2Go rather than a Terminal is that you can close the connection winow and re-open it later, leaving all your processes running as you left them.

If you stop the instance and then later restart it, the IP address may change. You will need to change this in your X2Go settings and allow the connection when prompted.

**X2Go settings AWS EC2 instance**

| Option | Setting |
| :--- | :--- |
| Session name | *e.g.* AWS |
| Host | *IP address for the VM, e.g.* 192.171.139.44 |
| Login | ubuntu |
| Use RSA/DSA key for ssh connection | *The path to your* `keys/ukca_keypair.pem` *key file (navigate via button)* |
| Session type | *Select* LXDE *from drop-down menu* |

### UM Install Commands

**Note** that prior to UMvn11.1 the UM install won't work due to the `gfortran` compiler version used at Ubuntu 18.04. Post vn11.2 the setting 

	grib_library: libgrib-api-dev 

must be made in `group_vars/all.yml` (this is the default). The current roles will perform the equivalent to `sudo install-um-extras`, but following that you will need to run the following commands in sequence (e.g. for vn11.8):

    um-setup -s fcm:shumlib.x_tr@um11.8
    install-um-data
    install-ukca-data
    install-rose-meta
    fcm checkout fcm:um.x_tr@vn11.8 UM11.8
    cd UM11.8
    rose stem --group=install,install_source -S CENTRAL_INSTALL=true -S UKCA=true
    rose stem --group=kgo,ukca -S GENERATE_KGO=true
    rose stem --group=fcm_make --name=vn11.8_prebuilds -S MAKE_PREBUILDS=true
    rose stem -O offline --group=fcm_make --name=vn11.8_offline_prebuilds -S MAKE_PREBUILDS=true

After the `um-setup` command you will need to close and re-open a terminal.

Availble suites for the VM can be found on the [UKCA Website](https://www.ukca.ac.uk/wiki/index.php/GA7.1_StratTrop_suites#Virtual_Machine_Development_Suites).
