## Git Ops Starter

Git ops starter is repository addressing ABC, Inc. company's all infrastructure needs. Before diving in read the story how this repository was born.

## ABC, Inc.

ABC, Inc. is a regular or spectacular SaaS startup. They are developing their platform mainly utilizing Microsoft technologies, including C#, .Net deployed in Azure App Services and Azure Functions. For some of external services like Superblocks as well as some internal long running jobs they utilize AKS (k8s). Data is mostly stored in a PostgresSQL database (flexiable servers managed by Azure), they cache in Redis (managed service by Azure) and send cross-components messages in Azure Service Bus. Ah and also for one of their data-sensitive components they use MongoDB Atlas. Front-end is written in Typescript and they use Next.js deployed to Vercel. For DNS management they use Cloudflare, for SSL certificates they use lets-encrypt and for logging/monitoring they use DataDog. And for some wired reason they use Azure Devops pipelines instead of GitHub Actions.

## Story

Bob, co-founder and a guy who had experience with Azure, was handling all of these. Creating AppServices, configuring App_Settings, Connection_Strings, DNS verification records. All by bare hands. It was fun at first. But then as any startup, ABC also went through major 2-3 pivots until we started feeling the ‘zen’ of any startup - “product-market-fit.” In a startup world, pivot simply means you had an A idea; now, it's a B. But what does it really mean for technical savages like Bob? You had the A1 service, referencing the A2 service with A3 Database. You had entity names that are suited and designed for A; the dependencies like A1 -> A2 made sense for A. Now you have to change everything from A to B. You don’t have time to rewrite everything. You already have some components that don’t need to be changed - at least logically, so you end up applying changes only in “UI” and make everything somehow work. After a few pivots, you have a lovely “C Idea” UI and “A, B, C, D, E” backend and “A0, A1, B1, b999, 7E, DDD” infrastructure. With each day passing, Bob felt more pressure; he slowly releases that if he don’t do something with this now, everything will simply explode. The next day, after having a horrible night - Bob took a paper - in fact just an MD file and wrote down all requirmenets.

## Requirements

- Should have sperate dev/prod environment and ability to have more enviroments like qa/staging relativly easier
- Adding new AppServices/AzureFunctions and k8s deployments should require minimal steps from developer
- Prod environment should be fully in v-net and authorized developers should have vpn acess to it
- All the configurations, connections strings for all deployments should be configured automatically\
- All infrastructure deployments should be defined as a code, so it makes any change fast/easy and trackable

Out of these requirements Bob decided to use Terraform for managing Azure infrastructure and Fluxcd for managing AKS (k8s).

## Architecture

Information about overall architechture desing, separate workspaces for k8s, devops, dev and prod environment

## Underwater stones

Information about Terraform cloud agents, azure build agents, link to doc how to build agent on premise, cloudflare module version and more

## Repository structure

Information on how the repository is structured

## Call outs

Include links to specific implementations, like vpn gateway, mongodb atlas private link and more

## What's next

- We are more than happy to have a debate on Bob's decisions
- ABC Inc, is planning to duplciate their infrastructure in AWS and Google Cloud
