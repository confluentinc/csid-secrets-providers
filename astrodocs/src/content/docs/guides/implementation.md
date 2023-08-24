---
title: Implementation
tableOfContents:
    maxHeadingLevel: 3
---

## How should I implement this library?

A complete setup of Confluent Secrets will go through the following phases:

1.  Installation of the libraries
2.  Creation and installation of the property files
3.  Restart of the components and health check
4.  Test of the added functionality

## Installation: What files do I need, and where do I put them?

The Confluent Secrets Providers Accelerator is provided as Java jar libraries to be installed in your Java class path.

Note: ordering of libraries in Java class path is important.
Accelerator libraries such as this should be loaded first.

Note: it is not recommended to install libraries for multiple components sharing a node (e.g. Schema Registry and Connect).

If necessary, then use separate class paths to be explicit for each component.

## Installation in the Java class path

Using the table below, copy the libraries required by your use case into your existing class path or a new folder.

The class search path (class path) can be set using either the `-classpath` option when calling a JDK tool (the preferred method) or by setting the `CLASSPATH` environment variable.

The `-classpath` option is preferred because you can set it individually for each application without affecting other applications and without other applications modifying its value.

## Installation via the CLI

Update the following with the specific provider to be installed:

```bash
confluent-hub install confluentinc/csid-config-provider-aws:latest
```

## List of libraries (current version, supports CP 5.5.x and up)

| Required Libraries                        | Description                                                   |
|-------------------------------------------|---------------------------------------------------------------|
| csid-config-provider-common-{version}.jar | Main library for secrets provider, required for all use cases |

| Optional Libraries                        | Description                                    |
|-------------------------------------------|------------------------------------------------|
| csid-config-provider-aws-{version}.jar    | AWS Secrets library for secrets management     |
| csid-config-provider-azure-{version}.jar  | Azure KeyVault library for secrets management  |
| csid-config-provider-gcloud-{version}.jar | Google Cloud library for secrets management    |
| csid-config-provider-vault-{version}.jar  | Hashicorp Vault library for secrets management |

## Configuration

Once the libraries required for your use case have been installed in the
Java classpath, it is time to configure encryption.

Configuration is done via standard Java `Properties` objects. Meaning, configuration can be specified in properties files, code, environment variables, etc.

