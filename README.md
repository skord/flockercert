# Flocker Node Cert Vault

on a node with all the keys and certs generated... tl;dr:
```
docker run -p 9292:9292 --volume /root/flocker:/etc/flocker:ro --name flockercert skord/flockercert
```

Where /root/flocker has your signing keys and certs. 

A auth token is generated when you start the container, use it to get the generated creds:

```
wget "http://ip.add.re.ss:9292/token.tar?AUTH_TOKEN=U146MNt0jQ1MxLhOsn48DoZHVfYyKoosRxYFQtmfJC4itqyoqOPY3Q&AZ=us-east-2"
```

The token and the AZ are required parameters.

This, of course, will allow any node that has the token to connect to your cluster, so you should really be careful to have a lot of security around the machine that runs this service. This is primarily meant for sitations like AWS AutoScaling groups.

container environmental variables:

FLOCKER_KEY_DIR: Where in the container your flocker keys and certs are mounted.
CLUSTER_CRT_NAME: What your cluster's cert is named
FLOCKER_CONTROL_HOST: Duh. This gets written into the generated agent.yml
FLOCKER_DATASET_BACKEND: defaults to aws, only supports that now.
AWS_ACCESS_KEY_ID: so you can make mounts
AWS_SECRET_ACCESS_KEY: you need this too. 
