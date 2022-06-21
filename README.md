# aws-ukca

Ansible playbooks and AWS scripts for creating UKCA training VMs on an AWS EC2 instance. This is based on the Vagrant-based [Met Office Virtual Machine](https://github.com/metomi/metomi-vms) and previous work on using Ansible for this VM on the [JASMIN Unmanaged Cloud](https://github.com/theabro/ukca-playbook). 

Based on instructions from [Dave Sugden (April 2020)](https://davelms.medium.com/use-ansible-to-create-and-configure-ec2-instances-on-aws-cfbb0ed019bf) and [Vivek Gite (February 2018)](https://www.cyberciti.biz/faq/how-to-create-aws-ec2-key-using-ansible/), as well as general Googling. Many thanks to Courtney Waugh of AWS for help and advice with the AWS scripts.

Tested on macOS 12.3.1. On macOS you may first need to

	export PATH="/Users/[YOUR USERNAME]/Library/Python/3.8/bin:$PATH"

This is a 5 stage process:

1. Create a user on the AWS Console
2. Create the EC2 instance.
3. Provision the EC2 instance with the required packages and settings to run FCM, Rose, & Cylc and prepare it for UM-UKCA use before saving it as an Amazon Machine Image (AMI)
4. Use CloudFormation ton create a virtual private cloud (VPC) to host the training instances
5. Use the AWS-CLI to create as many instances are required within the VPC, along with key files to connect to each instance

### Chose your region

On the [AWS console](https://aws.amazon.com/) you should choose the region where you want the VM to be provisioned. You can find the list of regions by using the drop-down menu on the top right of the page. The defualt settings may put you in `us-east-2` (US East (Ohio)), but you may want to change this to, e.g., London (or `eu-west-2`). 

There are many different types of EC2 VMs (e.g. Ubuntu, Amazon Linux etc.), which are identified by their unique **ami-** identifier. This identifier is also unique to a particular region. The setting for Ubuntu 18.04 LTS in the London (`eu-west-2`) region has already been selected in the `roles/create-ec2-instances/vars/main.yml` file. If you wish to use a different region you will need to search for the correct _ami-_ identifier from the **Launch instance** option within the EC2 Dashboard and then set this in the Vagrantfile accordingly.

### Create a user

You will need to create a user with the correct permissions to access your EC2 VM, which again is done via the [AWS console](https://aws.amazon.com/). This done within the **IAM Dashboard** (Identity and Access Management). On the console front page click the **All services** drop-down menu, and then click **IAM** under the "Security, Identity, & Compliance" section.

Under **Access Management** click **Users** and then click **Add user**. You should give them a name, e.g. _ukca_ etc.. Tick the box for **Programmatic access** and then click the **Next: Permissions** button.

Here you should click the tab labelled **Attach existing policies directly** and search for **AmazonEC2FullAccess** and then tick the check-box next to this option. Now click the **Next: Tags** button. You can then click the **Next: Review** button. 

Now click **Create user**. This will bring you to a page listing the username, the _Access key ID_ and the _Secret access key_. **THE SECRET ACCESS KEY INFORMATION WILL BE DISPLAYED ONLY ONCE**. 

You should download and save the `.csv` file containing this information. Again, do not upload this information to a public repository.

Before you create your EC2 instance you should install the [AWS CLI](https://aws.amazon.com/cli/) and run the 

	aws configure

to set your IAM's `aws_access_key_id`, `aws_secret_access_key`, and default `region` (e.g. `eu-west-2` for London). These are put in the `~/.aws/credentials` and `~/.aws/config` files.

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

	ansible-playbook -v provision_vm.yml -i inventory

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

Once your VM is provisioned you will need to stop it via the AWS web console and change its instance type to at least a **t2.large** to provide enough vCPUs and memory to run UKCA. Large and more powerful instance types are also available.

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
    rose stem --group=fcm_make --name=vn11.8_prebuilds -S MAKE_PREBUILDS=true
    rose stem -O offline --group=fcm_make --name=vn11.8_offline_prebuilds -S MAKE_PREBUILDS=true
    rose stem --group=kgo,ukca -S GENERATE_KGO=true

After the `um-setup` command you will need to close and re-open a terminal.

Availble suites for the VM can be found on the [UKCA Website](https://www.ukca.ac.uk/wiki/index.php/GA7.1_StratTrop_suites#Virtual_Machine_Development_Suites).

To remove the existing MOSRS information, you need to delete the following file:

    rm .subversion/auth/svn.simple/2be6a67d04b1c8c6d879daafa52fd762

## Turn this instance into an Amazon Machine Image

Once you have finished all the steps above and the UM is installed and you have removed the MOSRS information, power the EC2 instance down using the AWS web console. Navigate to the **instance summary** and use the **instance state** drop-down menu to select **stop instance**.

Once it is in a **stopped** state go to the **Actions** drop-down menu at the top right and select **images and templates** and then **create image**. 

You will need to give it a short-ish descriptive name and a longer description. You can change the volume size if desired, and you may want to ensure that the *delete on termination* option is selected for the volume. This ensures that the volume is deleted when the instance is terminated. If this is not selected you will need to delete the volumes separately.

When you are happy with the options, click the **create image** button on the bottom right. It will a short amount of time to create the image, and when complete the image can be found in the **Images** section of the left-hand naviagation menu, in the **AMIs** section. 

You will need to make a note of the **AMI ID** assigned to your image, as you will need it in the next section.

## Additional AWS scripts used to provision the EC2 instances for the students

Once you have install the UM and the necessary files, you can then use the scripts contained within the [`src/`](src/) directory to create a virtual private cloud (VPC) in your AWS account to host the VMs, create a security group for them, and then create keys and instances to give to the students.

### Using CloudFormation to create a VPC to host the training EC2 instances

To create the network the EC2 instances will reside in, the file [UKCACloudFormationTemplate.json](src/UKCACloudFormationTemplate.json) should be used within [CloudFormation](https://aws.amazon.com/cloudformation/) to create the virtual private cloud, security group, and public subnets used by the [create-ec2.sh](src/create-ec2.sh) script. These settings have been adapted from the [VPC_With_Managed_NAT_And_Private_Subnet.yaml](https://github.com/awslabs/aws-cloudformation-templates/blob/master/aws/services/VPC/VPC_With_Managed_NAT_And_Private_Subnet.yaml) and then converted to `.json` using the CloudFormation designer.

![Diagram showing the network layout within CloudFormation from the UKCACloudFormationTemplate.json](media/template1-designer.png?raw=true "Network layout within CloudFormation")

### Using AWS-CLI to create keys and EC2 instances

You will need the **AMI ID** from the image you created above and enter this in the `ami=` line in the [create-ec2.sh](src/create-ec2.sh) script.

Whether keys and instances are created or not will depend on whether or not a `keys/ukca_key_trXX.pem` (for keys) and a `keys/ukca_vm_tr01.json` (for instances) exists. If both files exist for e.g. `XX=01` and 2 instances are requested to be created, in fact only the second one will be provision as the script assumes that the first already exists. If the `.pem` file exists and the `.json` file does not then the key will **not** be created but the instance will be (and vice versa). 

It is therefore important to remember to delete any `ukca_key_trXX.pem` and `ukca_vm_tr01.json` files in the `keys/` directory, terminate any previous instances, and remove the corresponding keys from the AWS web console before creating new keys and instances, as they will not be created unless the corresponding files have been removed.

**Note** here **NOT** to delete the `ukca_keypair.pem` file that is the key for the instance provisioned using the Ansible method described above.

When CloudFormation has created the VPC, copy the relevant information from the console, e.g.

    vpc='vpc-0ef173dcfd55cdc70'
    sgid='sg-02ea177be98d549ff'
    subnet0='subnet-0974c239cea07ef9e'
    subnet1='subnet-0cdb50524da13885f'

into the [create-ec2.sh](src/create-ec2.sh) script then `cd` into the `src/` directory and run

    bash create-ec2.sh N 

where `N` is the number of instances you want to create. This will then create corresponding files, `ukca_tr_XX.pem` and `ukca_vm_trXX.json`, in the `keys/` directory. You should specify both subnets and the script will distribute the instances between both of them.

However, the information in the .json files will not include the public IP address information at this time as these won't have been assigned. Once the EC2 instances have all started and are running, you can use the script [get-ec2-ip.sh](src/get-ec2-ip.sh) to return the IP address information, e.g.

    bash get-ec2-ip.sh | sort
    ukca_vm_tr01,ukca_key_tr01,3.8.192.184
    ukca_vm_tr02,ukca_key_tr02,18.168.205.105
    ukca_vm_tr03,ukca_key_tr03,35.177.89.5
    ukca_vm_tr04,ukca_key_tr04,52.56.250.236
    ukca_vm_tr05,ukca_key_tr05,3.8.139.243
    ukca_vm_tr06,ukca_key_tr06,13.40.48.123

This can then be copied and pasted into an Excel spreadsheet using the [Convert Text to Columns Wizard](https://support.microsoft.com/en-us/office/split-text-into-different-columns-with-the-convert-text-to-columns-wizard-30b14928-5550-41f5-97ca-7a3e9c363ed7).

### EC2 Instance Connect

The file [EC2InstanceConnectTraining.json](src/EC2InstanceConnectTraining.json) should be used as a template for a policy to allow demonstrators to connect to the training EC2 instances using [EC2 instance connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Connect-using-EC2-Instance-Connect.html) when combined with the AmazonEC2ReadOnlyAccess policy. This means that they can see all instances but can only connect to the training ones (due to the tag Event:Training) under the ubuntu username. Here `AWSACCOUNTID` should be replaced with your AWS account ID without dashes.
