## LLfunds: Containerizing azure trigger functions
## Instructions
## Docker build
```bash
docker build -t <docker-name> .
```
## Docker image tagging 
```bash
docker tag <docker-name> alloan.azurecr.io/alloan_container:v1.0.0
```

## Pushing docker image to azure function app
```bash
docker push alloan.azurecr.io/alloan_container:v1.0.0
```

### **There are two azure trigger functions, autodnld_sync and generate_deal_data** 
<br>

1. The **autodnld_sync** trigger is for syncing deal data from intex server and updating the data in mount drive present.

## Commands to run from postman: 

```bash
{{host}}/api/autodnld_sync?command=data-sync
```

2. The **generate_deal_data** function is used to convert the deals saved on our mount drive to csv format. 

``` bash 
{{host}}/api/generate_deal_data?dealname=<deal-name>
```