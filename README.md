# Home Assistant Omada Add-On
This add-on brings the Omada Controller directly into Home Assistant running on a Raspberry Pi.

Currently, this Add-On only works for armv7-based Home Assistant installations. Pull-Requests for other architectures are welcome. 

---
**WARNING**

This add-on is in its development stage and not stable, yet. Please use it at own risk. It is knwon that the mongo db service is currently not able to properly
start on its own. To start the service, log into the the host system via SSH, log into the docker container via docker exec and run the following command:

 mongod --port 27217 --dbpath "../data/db" -pidfilepath "../data/mongo.pid" --logappend --logpath "../logs/mongod.log" --bind_ip 127.0.0.1

---

# Contribution 
This add-on is a fork of Matt Bentleys [docker-omada-cotroller](https://github.com/mbentley/docker-omada-controller) and would not have been possible without his excellent work. Other than in the original docker omada controller, this add-on stores all persistent data in the /data directory, so that it is compatible with Home assistant. 
