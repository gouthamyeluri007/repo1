# To enable ssh & remote debugging on app service change the base image to the one below
FROM mcr.microsoft.com/azure-functions/python:4-python3.8-appservice
# FROM mcr.microsoft.com/azure-functions/python:4-python3.8

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

RUN apt update; apt install -y perl build-essential unzip wget bash
RUN echo yes|cpan install IO::Socket::SSL 

COPY requirements.txt /
RUN pip install -r /requirements.txt

COPY . /home/site/wwwroot

WORKDIR /home/site/wwwroot/generate_deal_data/autodnld/scripts

RUN ln -sf $(which gzip) gzip
RUN ln -sf $(which unzip) unzip
RUN ln -sf $(which tar) tar
RUN ln -sf $(which perl) perl

ENV PROJECT_DIR=/home/site/wwwroot
