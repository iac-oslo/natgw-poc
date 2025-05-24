@export()
func getVNetName(prefix string) string => 'vnet-${prefix}'

@export()
func getUserAssignedIdentityName(prefix string) string => '${prefix}-mi'

@export()
var subnetName = 'snet-ds'

@export()
func getDeploymentScriptName(prefix string) string => 'ds-${prefix}'

@export()
func getPipPrefixName(prefix string) string => 'pipprofix-${prefix}'

@export()
func getPipName(prefix string) string => 'pip-${prefix}'

@export()
func getNatGatewayName(prefix string) string => 'natgw-${prefix}'
