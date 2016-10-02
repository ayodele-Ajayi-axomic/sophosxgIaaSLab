### Select your deployment location
{
# Get the current azure location list
$hash = Get-AzureRmLocation | Group-Object Location -AsHashTable
   
#Add an index number to select locations by
$counter = 0
    foreach($key in $($hash.keys)){
        $counter++
        $hash[$key] = $counter
    }

#Display the list, and ask for the index number
$hash
Write-Host -NoNewline "Enter the number (value) of the Azure region to use: "  -ForegroundColor Magenta; $locationnumber=read-host 

#Display the chosen location
$location = $hash.Keys | ? { $hash[$_] -eq $locationnumber }
Write-Host "Your Azure region is: " $location -ForegroundColor Green
}

### Define other deployment variables
{
$resourceGroupName = 'lbazurewesteurg'
$resourceDeploymentName = 'lbazurewesteuxgdp'
$templateFile = "C:\armdeployments\sophosxgSingle\DeploymentTemplate2.json"
$parameterFile = "C:\armdeployments\sophosxgSingle\parameters2.json"
}

### Create Resource Group
{
$azureResourceGroup = New-AzureRmResourceGroup `
                      -Name $resourceGroupName `
                      -Location $location `
                      -Verbose -Force
}

### Deploy the Sophos XG and two Windows Server to Azure
{
$deployment = New-AzureRmResourceGroupDeployment `
-Name $resourceDeploymentName `
-ResourceGroupName $azureResourceGroup.ResourceGroupName `
-TemplateFile $templateFile `
-TemplateParameterFile $parameterFile `
-Verbose -Force -DeploymentDebugLogLevel All -Mode Complete
}

### Apply a User Defined Route Table to LAN Subnet
{
$net = (Get-AzureRmVirtualNetwork -Name $deployment.Parameters.netName.Value -ResourceGroupName $resourceGroupName)
$netName = $net.Name
$lanNet = (Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $net -Name $deployment.Parameters.lanName.Value)
$lanName = $lanNet.Name
$wanNet = (Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $net -Name $deployment.Parameters.wanName.Value)
$wanName = $wanNet.Name
$routeTable = (Get-AzureRmRouteTable -ResourceGroupName $resourceGroupName)
$routeTableName = $routeTable.Name

$routeConfig = (Get-AzureRmRouteTable -ResourceGroupName $resourceGroupName | Get-AzureRmRouteConfig -Name "route_all_to_xg").Id
Set-AzureRmVirtualNetworkSubnetConfig `
    -VirtualNetwork $net `
    -Name $lanName `
    -AddressPrefix $lanNet.AddressPrefix `
    -RouteTableId $routeTable.Id | Set-AzureRmVirtualNetwork

}
