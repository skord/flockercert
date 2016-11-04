# Flocker Node Cert Vault

```
docker run -p 9292:9292 -e FLOCKER_AGENT_DATASET_BACKEND=aws --volume /root/flocker:/etc/flocker:ro --name flockercert skord/flockercert
```

Where /root/flocker has your signing keys and certs. You can set the environmental variable ```FLOCKER_GENERATE_VAULT=true``` if you want this app to create all the credentials you need.

A auth token is generated when you start the container, use it to get the generated creds:

```
curl -O http://ip.add.re.ss:9292/credentials.tar -d AUTH_TOKEN=U146MNt0jQ1MxLhOsn48DoZHVfYyKoosRxYFQtmfJC4itqyoqOPY3Q -d region=us-east-2 -d zone=us-east-2"
```

The token is required for access, you can pass the region and zone as parameters so they're correct in the generated agent.yml file.

This, of course, will allow any node that has the token to connect to your cluster, so you should really be careful to have a lot of security around the machine that runs this service. This is primarily meant for sitations like AWS AutoScaling groups.

container environmental variables:

FLOCKER_KEY_DIR: Where in the container your flocker keys and certs are mounted.
FLOCKER_CLUSTER_NAME: What your cluster's cert is named
FLOCKER_CONTROL_HOST: Duh. This gets written into the generated agent.yml
FLOCKER_GENERATE_VAULT: Generates all your keys and certs if set to "true"
FLOCKER_AGENT_DATASET_*.: anything prefixed with FLOCKER_AGENT_DATASET_ like FLOCKER_AGENT_DATASET_BACKEND=aws will be have the prefix stripped, it will be downcased, and put into agent.yml in the dataset section. If your region and zone are set via HTTP parameters, the HTTP parameters win. This is a handy place to set your AWS keys. 

