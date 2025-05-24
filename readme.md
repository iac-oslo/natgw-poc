# POC description

My customer uses Azure Secured Hub with Azure Firewall where all outbound traffic is routed through Azure Firewall egress IP. 
Now customer decided to switch to [Bring Your Own IP version of Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/secured-hub-customer-public-ip) (which is still in Public Preview though). Customer uses A LOT of partners APIs and some of them require whitelisting of Azure Firewall IP address. 
Following [recommendations](https://learn.microsoft.com/en-us/azure/firewall/firewall-known-issues) (search for `SNAT port exhaustion` section), we need to allocate a minimum of 5 IP addresses to new Azure Firewall. This means that we need to request all partners to whitelist new IP addresses. DR plan is also affected, as we need to request partners to whitelist new IP addresses for DR Azure Firewall as well. 

# The challenge

There are 10 new IP addresses that need to be whitelisted by partners and we need a way to test that each partner actually whitelisted all new IP addresses. So we need to setup a soft of lab environment where we can:
- configure outbound traffic to be routed through specified IP address
- execute TCP test towards each partner IP / FQDN at the specified port
- run this test automatically every day/week/month and generate report showing the progress of whitelisting

# The solution

After some whiteboarding and head scratching, we came up with the following solution for this test lab environment:

 - use Public IP Prefix with `/29` subnet mask to allocate 8 IP addresses for active environment and another `/29` for DR environment
 - provision all Public IPs from the Prefixes
 - use NAT Gateway to route outbound traffic through specified IP address
 - use Azure Deployment Scrips integrated into Private VNet https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-vnet
 - use Bicep to provision the environment

Here is the pseudo-code of the solution:

- provision lab environment 
- for each IP from available IP list
 - configure NAT Gateway to use specified IP address
 - deploy Deployment Script with pre-configured commands to test connectivity to partner IP / FQDN at the specified port
 - collect results
 - repeat for all IPs
- decommission lab environment

# The code

The POC implementation is located in [this repo](https://github.com/iac-oslo/natgw-poc) inside the `iac` folder. The IaC code is orchestrated by `main.bicep` script and all infrastructure resources are collected inside `modules/infra.bicep` file. 

Very simple version of the PowerShell script that tests connectivity towards partner IP / FQDN is located in `testPartners.ps1` file. The list of partners is implemented as an array of strings. 

```powershell
...
 $partners = @(
    'Foo,ifconfig.me,443',
    'Bar,ifconfig.me,80',
    'FooBar,ifconfig.me,22'
)
...
```
The `Deployment Scripts` code is stored in `test.bicep` file. It reads the content of `testPartners.ps1` file at deployment time using [loadTextContent](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-files#loadtextcontent) function and sends it to the [deploymentScripts](https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep) resource. 

```bicep
...
scriptContent: loadTextContent('testPartners.ps1')
...
```

The `deploy-and-test.ps1` script first deploys lab environment and then runs the tests. 

```powershell
❯❯ iac git:(main) 23:33 .\deploy-and-test.ps1
Deploying testlab infra...
Test Partners...
Updating NAT Gateway with new pip-natgw-poc-1 IP address...
Deploy and run test script...
[
  "Outbound IP - 20.100.26.81",
  "Testing Foo at ifconfig.me:443 - True",
  "Testing Bar at ifconfig.me:80 - True",
  "Testing FooBar at ifconfig.me:22 - False"
]
Updating NAT Gateway with new pip-natgw-poc-2 IP address...
Deploy and run test script...
[
  "Outbound IP - 20.100.26.83",
  "Testing Foo at ifconfig.me:443 - True",
  "Testing Bar at ifconfig.me:80 - True",
  "Testing FooBar at ifconfig.me:22 - False"
]
Updating NAT Gateway with new pip-natgw-poc-3 IP address...
Deploy and run test script...
[
  "Outbound IP - 20.100.26.82",
  "Testing Foo at ifconfig.me:443 - True",
  "Testing Bar at ifconfig.me:80 - True",
  "Testing FooBar at ifconfig.me:22 - False"
]
Updating NAT Gateway with new pip-natgw-poc-4 IP address...
Deploy and run test script...
[
  "Outbound IP - 20.100.26.80",
  "Testing Foo at ifconfig.me:443 - True",
  "Testing Bar at ifconfig.me:80 - True",
  "Testing FooBar at ifconfig.me:22 - False"
]
Deployment time:  00:08:53.6863343
```

This output can be used to generate a report showing the progress of whitelisting, but this is outside of the scope of this POC.

# Cleaning up

If you deployed this POC into your environment, donæt forget to clean up the resources when you finished.

```powershell
az group delete --resource-group rg-natgw-poc --yes
```


