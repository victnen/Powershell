Function Get-VMHostNetworkAdapterCDP {
<#
 .SYNOPSIS
 Function to retrieve the Network Adapter CDP info of a vSphere host.

 .DESCRIPTION
 Function to retrieve the Network Adapter CDP info of a vSphere host.

 .PARAMETER VMHost
 A vSphere ESXi Host object

.INPUTS
 System.Management.Automation.PSObject.

.OUTPUTS
 System.Management.Automation.PSObject.

.EXAMPLE
 PS> Get-VMHostNetworkAdapterCDP -VMHost ESXi01,ESXi02

 .EXAMPLE
 PS> Get-VMHost ESXi01,ESXi02 | Get-VMHostNetworkAdapterCDP

#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

Param
 (

[parameter(Mandatory=$true,ValueFromPipeline=$true)]
 [ValidateNotNullOrEmpty()]
 [PSObject[]]$VMHost
 )

begin {

 $ErrorActionPreference = 'Stop'
 Write-Debug $MyInvocation.MyCommand.Name
 $CDPObject = @()
 }

process{

try {
 foreach ($ESXiHost in $VMHost){

if ($ESXiHost.GetType().Name -eq "string"){

 try {
 $ESXiHost = Get-VMHost $ESXiHost -ErrorAction Stop
 }
 catch [Exception]{
 Write-Warning "VMHost $ESXiHost does not exist"
 }
 }

 elseif ($ESXiHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]){
 Write-Warning "You did not pass a string or a VMHost object"
 Return
 }

$ConfigManagerView = Get-View $ESXiHost.ExtensionData.ConfigManager.NetworkSystem
 $PNICs = $ConfigManagerView.NetworkInfo.Pnic

foreach ($PNIC in $PNICs){

$hash = @{}

$PhysicalNicHintInfo = $ConfigManagerView.QueryNetworkHint($PNIC.Device)

if ($PhysicalNicHintInfo.ConnectedSwitchPort){

$Connected = $true
 }
 else {
 $Connected = $false
 }

$TheNic = 
$TheVSwitch = ($ConfigManagerView.NetworkInfo.Vswitch | Where {$_.pnic -eq $pnic.key}).Name
$ThePortGroup = (($ConfigManagerView.NetworkInfo.Vswitch | Where {$_.Name -eq $TheVSwitch}).portgroup -replace("key-vim.host.PortGroup-","")) -join ","


$hash = @{

 VMHost = $ESXiHost.Name
 NIC = $PNIC.Device
 Vswitch = $TheVSwitch
 MacAdress = ($ConfigManagerView.NetworkInfo.Pnic | Where {$_.device -eq $PNIC.Device}).mac 
 PortGroup = (($ConfigManagerView.NetworkInfo.Vswitch | Where {$_.Name -eq $TheVSwitch}).portgroup -replace("key-vim.host.PortGroup-","")) -join ","
 IPAddress = ($ConfigManagerView.NetworkConfig.Vnic | Where {$_.Portgroup -in ($ThePortGroup -split ",")}).spec.IP.IPaddress -join ","
 Connected = $Connected
 Switch = $PhysicalNicHintInfo.ConnectedSwitchPort.DevId
 HardwarePlatform = $PhysicalNicHintInfo.ConnectedSwitchPort.HardwarePlatform
 #SoftwareVersion = $PhysicalNicHintInfo.ConnectedSwitchPort.SoftwareVersion
 #MangementAddress = $PhysicalNicHintInfo.ConnectedSwitchPort.MgmtAddr
 PortId = $PhysicalNicHintInfo.ConnectedSwitchPort.PortId

}
 $Object = New-Object PSObject -Property $hash
 $CDPObject += $Object
 }
 }
 }
 catch [Exception] {

 throw "Unable to retrieve CDP info"
 }
 }
 end {

 Write-Output $CDPObject
 }
}
