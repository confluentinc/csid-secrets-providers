---
title: Confluent Secrets Provider
tableOfContents:
    maxHeadingLevel: 3
---

Last update: April 4th 2023 (v1.0.7)

## Introduction

With a typical Confluent Kafka Platform installation, secrets are stored within that cluster only.

This software was developed as a Confluent Customer Solutions and Innovation Divison (CSID) Accelerator.
This CSID Accelerator enables the use of external third-party systems for securely storing and retrieving key/value pairs, commonly used for passwords, for example.
In some cases, this can be used to store symmetric keys and asymmetric (public/private) keys.

Third-party systems that integrations have been developed for, and included here:
- [Hashicorp Vault](https://www.vaultproject.io/)
- [Amazon Web Services (AWS) Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [Google Secret Manager](https://cloud.google.com/secret-manager)
- [Microsoft Azure Key Vault](https://azure.microsoft.com/en-gb/products/key-vault)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret)

Copyright 2023 Confluent Inc.