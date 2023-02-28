# Trino Tutorials

Welcome to the [Trino](https://trino.io/) getting started tutorial repository. 
This is a home for a set of preconfigured [Kubernetes](https://kubernetes.io/docs/home) 
deployments that are used to set up sandbox environments and showcase basic 
configurations in isolation to get new and existing users started playing
around with all the cool features Trino has, and more importantly, learn and
have fun.

We use [Helm](https://helm.sh), making the deployment of Kubernetes resources much
more streamlined. Trino has its own [Helm chart](https://trinodb.github.io/charts)
and for tutorials, we use the Helm charts of many other projects to make a
comprehensive stack. 

Stitching these individual deployments like Docker Compose is not available in 
Helm, so to make these tutorials bootstrappable akin to Docker, we have chosen to 
use the infrastructure-as-code framework, [Terraform](https://www.terraform.io). 
The choice of Terraform is only applicable to the tutorials repository  and 
should not be used or considered a general standard for Trino deployment. We
chose Terraform as it's the most documented with the largest community today.
The idea is that you'll have plenty of resources to fix any issues that may come
from using this repository while getting started. That said, this could easily
change moving forward.

If you're entirely new to Trino, you're not alone. Trino is a distributed SQL 
query engine designed to query large data sets distributed over one or more 
heterogeneous data sources. Check out some of our 
[use cases](https://trino.io/docs/current/overview/use-cases.html) 
to understand what Trino is and is not.  We also have a rascally little bunny 
mascot named 
[Commander Bun Bun](https://twitter.com/trinodb/status/1357416368543588356) 🐇.

## Requirements

See related 
[requirements in the Trino documentation](https://trino.io/docs/current/installation/kubernetes.html#requirements) 
to set up a local environment.

## Layout

The directories in this repo are organized by concepts such as 
object storage, [connectors](https://trino.io/docs/current/connector.html), 
[security](https://trino.io/docs/current/security.html), 
[fault-tolerance](https://trino.io/docs/current/admin/fault-tolerant-execution.html),
or basics. In order to run the environment, you need to be in
one of these directories that have a docker-compose.yml file in it. The second
level of directories contain the actual environment and tutorial directories
themselves. In order to run the environment, you need to be in one of these
directories that have a docker-compose.yml file in it.

## Running Trino

To run Trino, navigate to any of the directorires with a `main.tf` file in them and type:

```
terraform apply [--auto-approve]
```

## Destroying Trino

To destroy Trino, navigate to the directory of the Terraform deployment you want to decommision and type:

```
terraform destroy [--auto-approve]
```

