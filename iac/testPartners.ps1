 $partners = @(
    'Foo,ifconfig.me,443',
    'Bar,ifconfig.me,80',
    'FooBar,ifconfig.me,22'
)

$output = @()
$result = (curl ifconfig.me -s)
$output += 'Outbound IP - {0}' -f $result
foreach ($partner in $partners) {
    $parts = $partner -split ','
    $name = $parts[0]
    $ipOrFqdn = $parts[1]
    $port = $parts[2]
    
    $result = (Test-Connection $ipOrFqdn -TcpPort $port)
    $output += 'Testing {0} at {1}:{2} - {3}' -f $name, $ipOrFqdn, $port, $result
}
Write-Output $output
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['results'] = $output
