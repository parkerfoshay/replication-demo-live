# Server provisioning script for the repl-video-guide project:
# Create three Linux servers running Ubuntu 20.04 LTS

# Create new Linux user for each server
adduser admin

exit

ssh admin@<server-ip>

# Update the server

sudo apt update

# Open the firewall on server 1 for server 2 and 3

sudo ufw allow from <server-2-ip> to any port 27017
sudo ufw allow from <server-3-ip> to any port 27017

# Open the firewall on server 2 for server 1 and 3

sudo ufw allow from <server-1-ip> to any port 27017
sudo ufw allow from <server-3-ip> to any port 27017

# Open the firewall on server 3 for server 1 and 2

sudo ufw allow from <server-1-ip> to any port 27017
sudo ufw allow from <server-2-ip> to any port 27017

# Install MongoDB on all three servers https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/

wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt-get update


sudo apt-get install -y mongodb-org

# update the /etc/host file on all three servers

sudo nano /etc/hosts

# add the following lines to the /etc/host file on all three servers

173.230.135.160     mongodb.repl.member-one
45.79.115.124       mongodb.repl.member-two
139.177.192.212     mongodb.repl.member-three

# The /etc/host file should look like this on all three servers:

[](/images/hosts-file.png)

# From this point forward, all commands will be run on video

# Update the /etc/mongod.conf file on all three servers

sudo nano /etc/mongod.conf

# Add the following lines to the /etc/mongod.conf file on all three servers

# SERVER 1

====================================================================================================

# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
#  engine:
#  wiredTiger:

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1,mongodb.repl.member.one


# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  keyFile: /etc/mongodb/pki/mongod-keyfile
  authorization: enabled

#operationProfiling:

replication:
  replSetName: mongodb-repl-example


#sharding:

## Enterprise-Only Options:

#auditLog:

#snmp:

====================================================================================================

# SERVER 2

====================================================================================================

# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
#  engine:
#  wiredTiger:

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1,mongodb.repl.member.two


# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  keyFile: /etc/mongodb/pki/mongod-keyfile
  authorization: enabled

#operationProfiling:

replication:
  replSetName: mongodb-repl-example


#sharding:

## Enterprise-Only Options:

#auditLog:

#snmp:

====================================================================================================

# SERVER 3

====================================================================================================

# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
#  engine:
#  wiredTiger:

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1,mongodb.repl.member.three


# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  keyFile: /etc/mongodb/pki/mongod-keyfile
  authorization: enabled

#operationProfiling:

replication:
  replSetName: mongodb-repl-example


#sharding:

## Enterprise-Only Options:

#auditLog:

#snmp:

====================================================================================================

# Create the /etc/mongodb/pki directory and generate the keyfile on server 1

sudo mkdir -p /etc/mongodb/pki

openssl rand -base64 756 > /tmp/mongod-keyfile

chmod 0400 /tmp/mongod-keyfile

sudo mv /tmp/mongod-keyfile /etc/mongodb/pki/

sudo chown -R mongodb. /etc/mongodb/pki

sudo systemctl restart mongod

# Copy the keyfile from server 1 to server 2 and server 3

sudo cat /etc/mongodb/pki/mongod-keyFile

# Create the /etc/mongodb/pki directory on server 2

sudo mkdir -p /etc/mongodb/pki/

sudo chown -R mongodb:mongodb /etc/mongodb/pki/

chmod 0400 /etc/mongodb/pki/

sudo nano /etc/mongodb/pki/mongod-keyfile

# Paste in key

sudo systemctl restart mongod

# Create the /etc/mongodb/pki directory on server 3

sudo mkdir -p /etc/mongodb/pki/

sudo chown -R mongodb:mongodb /etc/mongodb/pki/

chmod 0400 /etc/mongodb/pki/

sudo nano /etc/mongodb/pki/mongod-keyfile

# Paste in key

sudo systemctl restart mongod

# Create the MongoDB replica set on server 1

mongosh

use admin

rs.initiate(
  {
     _id: "mongodb-repl-example",
     version: 1,
     members: [
        { _id: 0, host : "mongodb.repl.member.one" },
        { _id: 1, host : "mongodb.repl.member.two" },
        { _id: 2, host : "mongodb.repl.member.three" }
     ]
  }
)

# create a user on server 1

db.createUser({
   user: "dba-admin",
   pwd: "dba-pass",
   roles: [
     {role: "root", db: "admin"}
   ]
 })

# exit the mongo shell and connect to the replica set using the new user

exit

mongosh "mongodb://dba-admin:dba-pass@173.230.135.160:27017,45.79.115.124:27017,139.177.192.212:27017/?authSource=admin&replicaSet=mongodb-repl-example"

# Verify the replica set is working

rs.status()

# trigger an election

rs.stepDown()