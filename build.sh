#
# Copyright Confluent 2021
#

mvn clean package

find . -type f -name '*.zip' | xargs -I '{}' cp '{}' target/
