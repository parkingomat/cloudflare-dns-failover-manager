# cloudflare-dns-failover-manager
Cloudflare DNS Failover Manager

A lightweight container that monitors via curl a list of Public IPs with custom health checks. According to check result, it adds or removes DNS entries in cloudflare via cloudflare API. It is a free way to immitate cloudflare's load balancing feature. It is build entirely on bash to avoid any dependencies


# Usage:

Create a Kubernetes Cron Job to run every X minutes and use the following eviroment variables to configure the healthchecks

SEARCHSTRING= A string in the body of the response to look for in order to validate response. If empty check wil be skipped

SEARCHMETHOD= The method will be useg by curl (GET / HEAD / POST)

SEARCHTIMEOUT= How much time in seconds we have to wait in order to consider the request failed because of time out

SEARCHURL= The full url to check eg. https://example.com/check

SEARCHZONE= The domain we will use to update cloudflare zone eg example.com

SEARCHEXPECTEDCODE= Expected status code of the request eg 200, 201, 301 etc

SEARCHIPS= IP addresses that will be checked. They must be space separated "8.8.8.8 8.8.4.4 1.1.1.1"

#CLOUDFLAREACCESSTOKEN= The access token (bearer) for your account. 

CLOUDFLAREPROXY= Configure if records will use proxy mode or not. Valid values are 'true' and 'false' 
