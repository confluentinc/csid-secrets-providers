# Introduction

* [Hashicorp Vault](vault)
* [AWS Secrets Manager](aws)
* [Google Secret Manager](gcloud)
* [Microsoft Azure Key Vault](azure)

## Releasing

Change the version
```bash
mvn versions:set -DnewVersion=1.0.3-SNAPSHOT
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