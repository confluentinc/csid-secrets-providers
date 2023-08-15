# Setting up Spiffe Spire Locally

Setting up spire locally was pretty painful, so I'll include a doc here describing what I've done
so others might be able to debug this easily in the future.

## Prerequisites

You'll need Docker and Docker Compose.

You'll also need to be able to pull images from the non-prod Google Artifact Registry (GAR).
You can follow [this](https://confluentinc.atlassian.net/wiki/spaces/TOOLS/pages/2799735045/Docker+Migration+FAQ#GCP) guide on how to do that.

## Idea

The idea is that we will start the spire server and the spire agent in two docker containers. 
We need to customize the spire agent a little so we'll run our own custom docker image for that. 
Spire works by communicating over unix sockets, but unfortunately we can't mount unix sockets
past the docker hypervisor on mac, i.e. we can't communicate directly to the unix socket in the 
spire agent docker container. See [here](https://github.com/docker/for-mac/issues/483) for more info, 
but essentially it was too hard.

So what we'll do is use a tool like `socat` to forward the docker container's unix socket traffic
to a TCP port, and we'll expose that TCP port to the host machine. We can then communicate with that
TCP port to talk to the Workload API.  

At the time of writing this document, that TCP port is port `31523` on the host machine. 

## Steps

1. Just run `make start-spire`
2. To stop run `make stop-spire`

## Resetting

Make sure you've stopped all the spire containers by doing `make stop-spire`.

The spire server container uses a volume `dbdata` that contains the registration entries and other things it needs.
To reset this data, we just need to delete the volume.

You can list the docker volumes by doing `docker volume ls`.

To remove, you can do `docker volume rm spire_dbdata`. 

Then run the steps again.