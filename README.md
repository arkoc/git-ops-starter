# :wrench: GitOps Starter

The GitOps Starter is designed to address all of ABC, Inc.'s infrastructure needs. Before diving into its capabilities, let's explore the origins of this repository.

## :v: Why?

This is an inniciative of creating the most comprehensive GitOps Starter project.

- GitOps Starter can be a valuable resource for teams that are new to GitOps and want to learn more about how to implement it in their continuous delivery process.
- GitOps Starter Project is a way for someone to contribute to the GitOps community and help advance the state of the art in GitOps.

## :office: ABC, Inc.

ABC, Inc. is a regular (or spectacular) SaaS startup. They develop their platform using the following technologies:

- C# and .Net Core, deployed in Azure App Services and Azure Functions
- AKS (external services like Superblocks and some long-running internal jobs)
- PostgresSQL database (flexible servers managed by Azure)
- MongoDB database (managed by Atlas and deployed in Azure)
- Redis (managed service by Azure)
- Azure Service Bus
- Typescript with Next.js and deployed in Vercel
- Cloudflare
- Lets-Encrypt
- Azure DevOps Pipelines
- Datadog

## :newspaper: Story

Bob, a co-founder and experienced Azure developer, was handling all of ABC, Inc.'s infrastructure manually. At first, it was fun, but as the company pivoted (i.e., changed its focus) multiple times, the infrastructure became a mess. Bob realized that everything would "explode" if he didn't do something to address the issue. So, he took a piece of paper (an .md file) and wrote down all the requirements for a better infrastructure.

## :rocket: Requirements

- A separate development and production environment, with the ability to easily add additional environments like QA or staging.
- Adding new AppServices or AzureFunctions, and deploying them to Kubernetes, should be straightforward and require minimal effort from the developer.
- The production environment should be fully within a virtual network, and authorized developers should have VPN access to it.
- Configuration and connection strings for all deployments should be handled automatically.
- Infrastructure deployments should be defined as code, allowing for quick, easy, and trackable changes.

Based on these requirements, Bob decided to use Terraform for managing Azure infrastructure and Fluxcd for managing AKS (Kubernetes).

## :crystal_ball: Architecture

The process for releasing code in production is as follows:

1. Code is committed/merged to the dev branch.
2. An Azure DevOps pipeline is triggered, which builds the code, runs unit tests, and deploys to the dev environment.
3. After testing and a release decision, the dev branch is merged to the main branch, which triggers another Azure DevOps pipeline to deploy the code to production.
4. This release management process may not be ideal, but it gets the job done with only a few minutes of downtime. Bob plans to improve it in the future.

Based on this process, we need the following:

- A development environment
- A production environment
- Build pipelines for each component
- Kubernetes manifest apply for non-Azure managed services.

### :interrobang: Separate workspace/branch for each environment?
Prons and conds

Bob decided to have branch for each environment and separate workspace associated with it.

### :interrobang: A separate k8s cluster for each environment?
Pros and cons

Bob decided to have one k8s cluster and different node pools for each environment.

### :interrobang: Automated deployment of Build Pipelines?
Pros and cons

Bob decided to have a separate terraform repo for deploying build pipelines.

***

To sum it up. We will have 4 loosly coupled workspaces. dev, prod, k8s for deploying AKS, devops for creating build pipelines. On top of that we will have separate repo - flux for managing k8s deployments.

Diagram

Some more in depsh explanation of diagram and the state dependecies.

Showcase how the new appservice and k8s deployment are added. The final result.

## :blue_book: Repository structure

The repository is organized by cloud provider. Right now ABC, Inc. is only running on Azure, but they have some plans on duplicating infra in AWS, Google Cloud or IBM Cloud (Is there a such a thing?)

- Main infrastructure [/azure/tf-infra](/azure/tf-infra)
- AKS setup [/azure/tf-k8s](/azure/tf-k8s)
- Azure DevOps Pipelines [/azure/tf-devops](/azure/tf-k8s)
- FluxCD k8s gitops [/azure/fluxcd](/azure/fluxcd)

## :file_folder: Terraform Environment Variables

Following are global secrets neccessary for configuring terraform connections to providers.

| Key  | Sensitive | Category | Description
| ----------------------------------- | ----- | ------- | ----------------------------------- |
| ARM_CLIENT_ID | X | env | key description |
| ARM_CLIENT_SECRET | X | env | key description |
| ARM_SUBSCRIPTION_ID | X | env | key description |
| ARM_TENANT_ID | X | env | key description |
| AZDO_GITHUB_SERVICE_CONNECTION_PAT | X | env | key description |
| AZDO_ORG_SERVICE_URL | X | env | key description |
| AZDO_PERSONAL_ACCESS_TOKEN | X | env | key description |
| CLOUDFLARE_API_KEY | X | env | key description |
| CLOUDFLARE_EMAIL | X | env | key description |
| DD_API_KEY | X | env | key description |
| DD_APP_KEY | X | env | key description |
| GITHUB_TOKEN | X | env | key description |
| MONGODB_ATLAS_PRIVATE_KEY | X | env | key description |
| MONGODB_ATLAS_PUBLIC_KEY | X | env | key description |
| VERCEL_API_TOKEN | X | env | key description |

For each specific terraform workspace there are separate variable files as well:
- [/azure/tf-infra/variables.tf](/azure/tf-infra/variables.tf)
- [/azure/tf-k8s/variables.tf](/azure/tf-k8s/variables.tf)
- [/azure/tf-devops/variabales.tf](/azure/tf-devops/variabales.tf)

## :pushpin:Call outs

- VPN Gateway Setup
- Azure AppServices/AzureFunctions Private Link setup
- Postgres/Redis Private Link Setup
- Private DNS Forwarder setup
- DataDog AppServices Extensions Setup
- Dashboard of components links generation
- Azure functions host keys authentication
- KeyVault access policies
- CertManager/LetsEncrypte k8s setup 

## :skull: Underwater stones

- Terraform Cloud Agents
- AzureDevops Build Agents
- Cloudflare version problem

## :space_invader: What's next?

- Engage with the community to discuss and improve upon Bob's decisions.
- ABC, Inc. plans to replicate their infrastructure in AWS and Google Cloud.
- Implement a release management process with near 0 downtime.

## :hearts: Aknowledgments
