# Confluent Secrets Provider

Last update: April 4 2023 (v1.0.7)

## Introduction

With a typical Confluent Kafka Platform installation, secrets are stored within that cluster only.

This software was developed as a Confluent Customer Solutions and Innovation Divison (CSID) Accelerator.
This CSID Accelerator enables the use of external third-party systems for securely storing and retrieving key/value pairs, commonly used for passwords, for example.
In some cases, this can be used to store symmetric keys and asymmetric (public/private) keys.

Third-party systems that integrations have been developed for, and included here:
- Hashicorp Vault
- Amazon Web Services (AWS) Secrets Manager
- Google Secret Manager
- Microsoft Azure Key Vault

Copyright 2022 Confluent Inc.