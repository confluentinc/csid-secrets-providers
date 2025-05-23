# Confluent Secrets Provider

version 1.0.17, updated May 13, 2024

## Introduction

With a typical Confluent Kafka Platform installation, secrets are stored within that cluster only.

This CSID Accelerator enables use of external third-party systems for securely storing and retrieving key/value pairs, commonly used for passwords, for example.
In some cases, this can be used to store symmetric keys and asymmetric (public/private) keys.

* [Hashicorp Vault](vault)
* [AWS Secrets Manager](aws)
* [Google Secret Manager](gcloud)
* [Microsoft Azure Key Vault](azure)
* [Kubernetes Secrets](k8s)
* [File System](common)

# Implementation

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
confluent-hub install confluentinc/csid-secrets-provider-aws:latest
```

## List of libraries (current version, supports CP 5.5.x and up)

| Required Libraries                        | Description                                                   |
|-------------------------------------------|---------------------------------------------------------------|
| csid-secrets-provider-common-{version}.jar | Main library for secrets provider, required for all use cases |

| Optional Libraries                        | Description                                    |
|-------------------------------------------|------------------------------------------------|
| csid-secrets-provider-aws-{version}.jar    | AWS Secrets library for secrets management     |
| csid-secrets-provider-azure-{version}.jar  | Azure KeyVault library for secrets management  |
| csid-secrets-provider-gcloud-{version}.jar | Google Cloud library for secrets management    |
| csid-secrets-provider-k8s-{version}.jar    | Kubernetes library for secrets management      |
| csid-secrets-provider-vault-{version}.jar  | Hashicorp Vault library for secrets management |

## Releasing

https://maven.apache.org/maven-release/maven-release-plugin/plugin-info.html for more info

```shell
# prepare a release by updating release versions. Don't proceed the extra commits
./mvnw clean release:prepare -DskipTests -Darguments=-DskipTests -DpushChanges=false -Dresume=false

# push the tag release
git push origin --tags

# Confirm that the build has started running in semaphore before pushing the remaining commits
# push the remaining commits
git push origin

# cleanup the backupfiles created by the release
./mvnw release:clean -DskipTests
```

Build the packages
```bash
./build.sh
```

Regenerate Documentation
```bash
./update-readme.sh
```

Update licenses
```bash
./update-license.sh
```

## Publishing new documentation

To publish new documentation, first ensure you have the latest version of the `csid-secrets-providers` repo.

Then run the following command:

```bash
# navigate to the astrodocs folder
cd astrodocs
npm i # only needed the first time
npm run gh-pages
```

## Accessing the documentation

To access the documentation navigate to [csid-secrets-providers GitHub Pages](https://confluentinc.github.io/csid-secrets-providers/)
or locally run the following commands

```bash
# navigate to the astrodocs folder
cd astrodocs
npm i # only needed the first time
npm run build
npm run preview
```

## Adding new documentation

When adding new documentation save the document as `<DOC_NAME>.md` in the `astrodocs/src/content/docs` directory.

Visit the [README](astrodocs/README.md) for more information.


## Evaluation Use Disclaimers

This software was developed as a Confluent CSID Accelerator.
For Accelerators, a Confluent Professional Services (PS) engagement investment and agreement may be required to cover the initial implementation, guidance through testing, and to provide additional time to support release/production readiness activities.
This agreement also includes our issuance of a license, and your acceptance of terms and conditions, to install and for usage of the Accelerator software.
Without a license, this software is not intended to be used outside of the examples or have the examples modified.
Confluent retains all intellectual property rights, in and to the Accelerator Software and any changes and other modifications thereto.

Copyright 2024 Confluent Inc.
