#
# Copyright Confluent 2021
#

mvn clean package
cp LICENSE aws/LICENSE
cp LICENSE azure/LICENSE
cp LICENSE gcloud/LICENSE
cp LICENSE vault/LICENSE

mvn license:format
