$stopwatch = [System.Diagnostics.Stopwatch]::new()
$stopwatch.Start()

$location = 'norwayeast'
$prefix = 'natgw-poc'
$resourceGroupName = "rg-$prefix"

 Write-Host "Deploying testlab infra..."
$deploymentName = 'deploy-infra-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
az deployment sub create -l $location --template-file main.bicep -p resourceGroupName=$resourceGroupName -p prefix=$prefix -n $deploymentName --output none

Write-Host "Test Partners..."
for ($i = 1; $i -le 4; $i++) {
     Write-Host "Updating NAT Gateway with new pip-$prefix-$i IP address..."
     az network nat gateway update -g $resourceGroupName -n "natgw-$prefix" --public-ip-addresses "pip-$prefix-$i" --output none
    
     Write-Host 'Deploy and run test script...'
    $deploymentName = 'test-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
    az deployment group create -g $resourceGroupName --template-file test.bicep -p prefix=$prefix -n $deploymentName --query properties.outputs.results.value
 }

$stopwatch.Stop()

Write-Host "Deployment time: " $stopwatch.Elapsed 
