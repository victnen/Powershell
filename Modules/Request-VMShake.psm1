function Request-VMShake {
<#
    .Synopsis
        Set all ESXi in a cluster in maintenance mode one by one. to force VM shake
    
    .DESCRIPTION
        Set all ESXi in a cluster in maintenance mode one by one. to force VM shake
    
    .PARAMETER Cluster
        Cluster on which perform the VMShake
        
    .EXAMPLE
        Request-VMShake -Cluster CLUS73_CUB200_LAB_BSZ_COMPUTE    
                  
    .OUTPUTS
        Boolean
    .Notes
        Author: Vincent Gitton
#>
[CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$Cluster
    ) 
Try
{   
  Write-Output "VM Shake on Cluster $($cluster)"
  Foreach ($esx in (get-cluster $cluster | Get-VMHost -State Connected))
  {
    Write-Output "Set $($esx) in maintenance"
    $task = Set-VMHost -VMHost $esx -State "Maintenance" -VsanDataMigrationMode NoDataMigration -RunAsync
    Start-Sleep -s 3
    Get-DrsRecommendation -Cluster $cluster | where {$_.Reason -eq "Host is entering maintenance mode"} | Apply-DrsRecommendation
    $vmhost = Wait-Task $task
    Write-Output "Set $($esx) as connected"
    $task = Set-VMHost -VMHost $esx -State "Connected" -RunAsync
    Start-Sleep -s 3
    Get-DrsRecommendation -Cluster $cluster
    Get-DrsRecommendation -Cluster $cluster | where {$_.Reason -eq "Host is entering maintenance mode"} | Apply-DrsRecommendation
    $vmhost = Wait-Task $task
    Return $true
  }
  Write-Output "End Of Script"
}Catch
{
  Return $false
}
 
