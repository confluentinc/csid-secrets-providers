# Change Log



### Features

- **Vault**: Added support for PEM-based SSL configuration with certificate-based authentication. New configuration options include `vault.ssl.pem_cert_path` (client certificate), `vault.ssl.pem_key_path` (client key), and `vault.ssl.pem_trust_path` (trusted CA bundle) for enabling mTLS authentication with HashiCorp Vault.

### Deprecations

- **AWS Secrets Manager**: Deprecated `secret.ttl.ms` configuration option. This configuration is no longer used and will be removed in a future release. A deprecation warning will be logged when this configuration is used.

## [1.0.10](https://github.com/confluentinc/csid-secrets-providers/releases/tag/csid-secrets-providers-1.0.10)

### Features and Fixes

- Bump undici from 5.23.0 to 5.26.3 in /astrodocs (#126)
- Bump @babel/traverse from 7.22.10 to 7.23.2 in /astrodocs (#127)
- Bump sharp from 0.32.4 to 0.32.6 in /astrodocs (#137)
- Updating vault library & kafka client (#155)

## [1.0.9](https://github.com/confluentinc/csid-secrets-providers/releases/tag/csid-secrets-providers-1.0.9)

### Features and Fixes

- Bump ch.qos.logback:logback-classic from 1.4.5 to 1.4.12 (#148)
- Bump com.azure:azure-sdk-bom from 1.2.16 to 1.2.18 (#132)
- Bump com.amazonaws:aws-java-sdk-bom from 1.12.461 to 1.12.595 (#144)
- Bump com.google.cloud:libraries-bom from 26.14.0 to 26.27.0 (#135)
- Add aws-java-sdk-sts dependency for IAM role for service account auth support in Kubernetes (#143)
- Bump zod from 3.21.4 to 3.22.4 (#122)
- Bump postcss from 8.4.27 to 8.4.31 (#110)

## [1.0.8](https://github.com/confluentinc/csid-secrets-providers/releases/tag/csid-secrets-providers-1.0.8)

### Features and Fixes

- CCET 337 reformat astrodocs (#34)
- Update README.md (#35)
- Fixing up manifest.json files to resolve URLs (#36)
- Create dependabot.yml (#37)
- Updated dependency libraries for minor and incremental versions (#68)
- Adding maven release plugin also correcting documentation (#69)
- Updating docs on github pages (#91)

## [1.0.7](https://github.com/confluentinc/csid-secrets-providers/releases/tag/1.0.7)

### Features and Fixes

- Adding FileProvider (#27)
- Updating BOMs for AWS, Azure, GCP libs (#28) 
- Update README.md to add needed examples for ansible and where to get the release file (#31)
- CCET 337 convert sphinx documentation to astrodocs (#33)
- Bump guava from 31.1-jre to 32.0.0-jre (#30)

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

## [1.0.3](https://github.com/confluentinc/csid-secrets-providers/releases/tag/1.0.3) (2022-07-14)

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

## [1.0.2](https://github.com/confluentinc/csid-secrets-providers/releases/tag/1.0.2) (2021-12-01)

### Features and Fixes

- Updated documentation
- CSIDG-97: update pom for correct package name (#10)
- CSIDG-97: Removing extraneous docs artifacts (#11)
- Small fix for sample properties auth.method vs login.by (#7)
- Hashicorpvault approle issue ... (#9)
- Updated and formatted documentation (#5)
- added ability to configure kv secrets engine version (#3)
- Updated pom logback version for CVE-2017-5929. (#4)

## [1.0.1](https://github.com/confluentinc/csid-secrets-providers/releases/tag/1.0.1) (2021-09-24)

### Features and Fixes

- Refactor introduced NPE for hanging config variables that were not removed. Ensured that all unit
  tests are checking that supplied configs from base class are not null. Fixes CSIDG-57. (#2)

## [1.0.0](https://github.com/confluentinc/csid-secrets-providers/releases/tag/1.0.0) (2021-09-10)

### Features and Fixes

- Initial release.
- Reconciled with confluent-secrets Accelerator project.

