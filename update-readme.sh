#
# Copyright Confluent 2021
#

mvn clean package
cp aws/target/README.md aws/README.md
cp azure/target/README.md azure/README.md
cp gcloud/target/README.md gcloud/README.md
cp vault/target/README.md vault/README.md
