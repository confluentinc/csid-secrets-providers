---
title: Releasing
tableOfContents:
    maxHeadingLevel: 2
---

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

## Evaluation Use Disclaimers

This software was developed as a Confluent CSID Accelerator.
For Accelerators, a Confluent Professional Services (PS) engagement investment and agreement may be required to cover the initial implementation, guidance through testing, and to provide additional time to support release/production readiness activities.
This agreement also includes our issuance of a license, and your acceptance of terms and conditions, to install and for usage of the Accelerator software.
Without a license, this software is not intended to be used outside of the examples or have the examples modified.
Confluent retains all intellectual property rights, in and to the Accelerator Software and any changes and other modifications thereto.

Copyright 2023 Confluent Inc.