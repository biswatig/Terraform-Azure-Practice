1. Install Azure CLI tool through terminal or otherwise following the Azure documenntation
	2. Go to vs code and type in az login 0r with az login --use-device-code(optional). It will take you to the browser and you will be logged in
	3.  az account show will show the account and az account list will show the subscriptions (https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)
	4. az account set --subscription="Azure for Students"  // to select the subscription in case of multiple subscription
	5. Now that we're logged into the Azure CLI - we can configure Terraform to use these credentials. To configure Terraform to use the Default Subscription defined in the Azure CLI - we can use the following Provider block: We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group


terraform fmt # to format terraform code before they are committed

terraform init #to initialize 

this creates a .terraform directory containing a compiled go file. It also creates a lock file that can constrain the version being used. This is typically to be committed to the repository. If we want to upgrade the version then we need to modify the version or just have to delete the file

terraform init is interested nothing except for provider related stuff. we can type a wrong code like feature, instead of features in the second code lock, i.e. provider "azurerm"{
	feature{}
}
yet it will compile...

terraform plan # shows us what is going to be built when we run terrfaorm apply. be careful mentioning the subscription id correctly before running this code

terraform apply # applies the above plan! with a success message. You can go and check your suscripptions and the resource group tab to see the new resource-group apper there

Now deploy a virtual network ([azurerm_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network)) ! 

for that we need to learn the attributes of other resources

we can create security_group for each virtual network mentioning access rules as well:
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group.html


....

>> terraform state list
azurerm_network_security_group.nsg1
azurerm_resource_group.rg1
azurerm_virtual_network.vnet1

>>terraform state show azurerm_virtual_network.vnet1 (#this will show the terraform state for that resource)
>> terraform show (will show all of the states)

#Terraform State

https://developer.hashicorp.com/terraform/language/state

Terraform must store state about your managed infrastructure and configuration. This state is used by Terraform to map real world resources to your configuration, keep track of metadata, and to improve performance for large infrastructures.

This state is stored by default in a local file named "terraform.tfstate", but we recommend storing it in Terraform Cloud to version, encrypt, and securely share it with your team.


#Destroy

terraform -destroy

so, orphaned resource is for example when we have something in the physical space but is it not being referenced in the code space and as a result it might just be sitting there without being called for or utilised. is that correct ?
ChatGPT
Exactly! An orphaned resource in the context of Terraform refers to a resource that exists in the real-world infrastructure (e.g., a VM or a network in Azure) but is no longer managed or recognized by Terraform, typically due to the absence or corruption of the Terraform state file (terraform.tfstate). This means Terraform won't take any actions on it (like modifying or deleting), even if you change your Terraform configuration, because as far as Terraform is concerned, it doesn't "know" that resource exists. Such resources might consume resources and incur costs while not being actively managed or utilized.

Record of Managed Infrastructure: The terraform.tfstate file keeps a record of the resources Terraform has created and is actively managing. It maps your configuration's resources to the real-world infrastructure.

Syncing Configuration with Reality: When you run terraform apply, Terraform refers to the terraform.tfstate file to understand the current state of the infrastructure and determine what changes are necessary to bring the real-world infrastructure in line with your configuration (as defined in your .tf files).

Preventing Duplicates and Conflicts: The state file ensures that Terraform recognizes existing resources. Without it, if you ran terraform apply multiple times, Terraform might attempt to create new instances of resources each time, leading to duplicates and potential conflicts.

Differential Management: The state allows Terraform to only make necessary changes. For instance, if you've added a new resource to your .tf file but made no changes to existing resources, Terraform will only create the new resource and leave the existing ones untouched. It determines this based on the state file.

State Locking (Advanced): In team environments, there's a feature called state locking which ensures that multiple team members don't apply changes at the same time, which could lead to conflicts or issues. This is especially important when the state is stored remotely (e.g., in a cloud storage bucket).

To sum up, the terraform.tfstate file is vital for Terraform to keep track of and manage infrastructure resources efficiently and safely. It ensures the synchronization between your Terraform configuration and the real-world infrastructure.

What is State Locking?
State locking does precisely what the name suggests: it locks the state file when someone is applying changes. This prevents any other applies from happening at the same time, which could corrupt the state file or result in unpredictable infrastructure changes.

Why is it Important?
Imagine two developers trying to apply changes to the same infrastructure at the exact same time but from different configurations. Their concurrent changes might conflict, causing one or both applies to fail and potentially leaving the infrastructure in an inconsistent state. Worse yet, if they're both trying to write to the state file simultaneously, it might corrupt the state file itself.

Real-world Scenario:
Consider a team of developers working on setting up a complex cloud environment using Terraform. They're rapidly iterating, with multiple team members making and applying changes.

Developer A starts a terraform apply to roll out a new version of an application.
At the same time, Developer B starts their terraform apply to scale the number of virtual machines.
Without state locking, both operations might try to modify the environment simultaneously. This could result in:
An inconsistent environment state where some changes are applied while others aren't.
A corrupted state file if both operations try to write to it at once.
How Does It Work?
When using backends that support locking (like AWS S3 with DynamoDB, Azure Blob Storage, Google Cloud Storage, etc.), Terraform will automatically lock the state file during operations that could write to it (like terraform apply or terraform destroy). If someone else tries to run an apply while the state is locked, Terraform will inform them that the state is locked and prevent them from proceeding.

Manually Locking/Unlocking (in supported backends):
Terraform also provides commands to manually manage state locks:

terraform state lock: Manually lock a state.
terraform state unlock: Manually unlock a state.
In practice, you shouldn't need these commands under normal operations, but they can be handy in case of issues.

Ensuring State Locking:
If you're working in a team environment, it's a good practice to use a Terraform backend that supports state locking. Not all backends do, so it's something to check when setting up Terraform for team use.

To summarize, state locking is a safeguard that prevents simultaneous Terraform operations from conflicting with each other, ensuring that infrastructure changes are applied consistently and safely.

Subnet and security group:

NSG Rule Association with NSG: The network_security_group_name = azurerm_network_security_group.nsg1.name in your rule (nsg1_rule1) is associating that rule to your network security group (nsg1).

NSG Association with Subnets: You're right that:

The azurerm_subnet_network_security_group_association is associating your nsg1 with subnet1 (the first subnet or subnet[0]).
The inline security_group = azurerm_network_security_group.nsg1.id is associating your nsg1 with subnet2.
Therefore, both subnet1 and subnet2 will be associated with nsg1 and by extension, any rules that are part of nsg1.

Multiple Rules in NSG: If you add another rule, say nsg1_rule2, and associate it with the same nsg1 (network_security_group_name = azurerm_network_security_group.nsg1.name), then nsg1 will have both nsg1_rule1 and nsg1_rule2 as part of its rule set. Both rules will be active and enforced by nsg1. The specific behavior of traffic will depend on the details of these rules, their priorities, and how they might overlap or conflict.

Just remember that NSGs can have multiple rules. Adding a new rule to an NSG doesn't replace the existing rules; instead, all rules coexist and are processed based on their priority. Traffic will be evaluated against each rule in the NSG starting from the lowest priority number to the highest, stopping at the first match.


In Azure, when you create a subnet within a Virtual Network, Azure reserves 5 IP addresses within each subnet for its own use:

x.x.x.0: Network address
x.x.x.1: Reserved by Azure for the default gateway
x.x.x.2, x.x.x.3: Reserved by Azure to map to the Azure DNS IP addresses
x.x.x.255: Network broadcast address
So, if you have a /24 subnet (which has 256 IP addresses in total: ranging from 0 to 255), and Azure reserves those 5 IP addresses, you're left with 251 available IP addresses for your use.

That's why you see 251 available IP addresses for a /24 subnet in Azure.

