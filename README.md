# oci-cockroachdb
This is a Terraform module that deploys [CockroachDB](https://www.cockroachlabs.com/) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure). It is developed jointly by Oracle and Cockroach Labs.

## Prerequisites
First off you'll need to do some pre deploy setup. That's all detailed [here](https://github.com/oracle/oci-quickstart-prerequisites).

## Clone the Module
Now, you'll want a local copy of this repo. You can make that with the commands:

    git clone https://github.com/oracle-quickstart/oci-cockroachdb.git
    cd oci-cockroachdb/terraform
    ls

That should give you this:

![](./images/git-clone.png)

## Initialize the deployment

NOTE: By default, a 3 node cluster is deployed. You may change the number of nodes to be deployed by changing the `instance_count` variable in `variables.tf` file.

We now need to initialize the directory with the module in it.  This makes the module aware of the OCI provider.  You can do this by running:

    terraform init

This gives the following output:

![](./images/terraform-init.png)

## Deploy the module
Now for the main attraction.  Let's make sure the plan looks good:

    terraform plan

That gives:

![](./images/terraform-plan.png)

If that's good, we can go ahead and apply the deploy:

    terraform apply

You'll need to enter `yes` when prompted.  Once complete, you'll see something like this:

![](./images/terraform-apply.png)

When the apply is complete, the infrastructure will be deployed, but cloud-init scripts will still be running.  Those will wrap up asynchronously.  So, it'll be a few more minutes before your cluster is accessible.  Now is a good time to get a coffee.

When the deployment is completed, it will show you the public IP of one of the instances created on Oracle Cloud Infrastructure (OCI). Using that public IP, you can browse the CockroachDB cluster's admin page on port 8080.

`http://<public IP of the load balancer>:8080`

![](./images/cockroachdb.png)

You can also connect to the cluster by using the [built-in SQL client](https://www.cockroachlabs.com/docs/stable/install-cockroachdb-mac.html) that comes with CockroachDB and use the public ip of the load balancer as the target host.

`cockroach sql --insecure --host=<public IP of the load balancer>`

## View the instance in the Console
You can also login to the web console [here](https://console.us-phoenix-1.oraclecloud.com/a/compute/instances) to view the IaaS that is running the cluster.

![](./images/console.png)

## Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy it:

    terraform destroy

You'll need to enter `yes` when prompted.

![](./images/terraform-destroy.png)
