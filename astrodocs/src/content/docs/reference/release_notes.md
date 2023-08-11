---
title: Release Notes
tableOfContents:
  maxHeadingLevel: 3
---

## [1.0.6](https://github.com/confluentinc/csid-secrets-providers/releases/tag/1.0.6)

### Features and Fixes

- Update email reference in SECURITY.md by @mkcops in #25
- CSIDG-362. by @jcustenborder in #26

## [1.0.5](https://github.com/confluentinc/csid-secrets-providers/releases/tag/csid-secrets-providers-1.0.5)

### Features and Fixes

- Build: Fixing repo location again by @paxtonhare in #23

## [1.0.4](https://github.com/confluentinc/csid-secrets-providers/releases/tag/csid-secrets-providers-1.0.4)

### Features and Fixes

- CSIDD-415: Adding Jenkinsfile to publish artifacts by @paxtonhare in #18
- Build: publish to s3 maven repo by @paxtonhare in #20
- Updating google Cloud provider by @paxtonhare in #21
- Updating maven repos by @paxtonhare in #22

## [1.0.3](https://github.com/confluentinc/csid-config-providers/releases/tag/1.0.3) (2022-07-14)

### Features and Fixes

- Removed token refresh subscription. Resolves CSIDG-221 (#17)
- Added better logging support for vault. Fixed pom so IDE properly displays logging. Fixes
  CSIDG-211. (#16)
- Kubernetes Secrets support added. Resolves CSIDG-201 (#15)
- Added check for empty data coming back from driver specific code. Added additional check when data
  is returned but keys are missing. Fixes CSIDG-184 (#14)
- Updated CODEOWNERS (Pull Request Reviewers) (#12)
- Include Vault prefixpath configuration parameter. Resolves CSIDG-147  (#13)

Thanks to Ivan Kunz, Venky Narayanan, Paxton Hare, and Jeremy Custenborder for contributions to this
release.

## [1.0.2](https://github.com/confluentinc/csid-config-providers/releases/tag/1.0.2) (2021-12-01)

### Features and Fixes

- Updated documentation
- CSIDG-97: update pom for correct package name (#10)
- CSIDG-97: Removing extraneous docs artifacts (#11)
- Small fix for sample properties auth.method vs login.by (#7)
- Hashicorpvault approle issue ... (#9)

## [1.0.1](https://github.com/confluentinc/csid-config-providers/releases/tag/1.0.1) (2021-09-24)

### Features and Fixes

- Refactor introduced NPE for hanging config variables that were not removed. Ensured that all unit
  tests are checking that supplied configs from base class are not null. Fixes CSIDG-57. (#2)

## [1.0.0](https://github.com/confluentinc/csid-config-providers/releases/tag/1.0.0) (2021-09-10)

### Features and Fixes

- Initial release.
- Reconciled with confluent-secrets Accelerator project.

