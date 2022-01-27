# Change Log

## [1.0.2](https://github.com/confluentinc/csid-config-providers/releases/tag/1.0.2) (2021-12-01)

### Features and Fixes
 - Updated documentation
 - CSIDG-97: update pom for correct package name (#10)
 - CSIDG-97: Removing extraneous docs artifacts (#11)
 - Small fix for sample properties auth.method vs login.by (#7)
 - Hashicorpvault approle issue ... (#9)

## [1.0.1](https://github.com/confluentinc/csid-config-providers/releases/tag/1.0.1) (2021-09-24)

### Features and Fixes
- Refactor introduced NPE for hanging config variables that were not removed. Ensured that all unit tests are checking that supplied configs from base class are not null. Fixes CSIDG-57. (#2)

## [1.0.0](https://github.com/confluentinc/csid-config-providers/releases/tag/1.0.0) (2021-09-10)

### Features and Fixes
- Initial release.
- Reconciled with confluent-secrets Accelerator project.

