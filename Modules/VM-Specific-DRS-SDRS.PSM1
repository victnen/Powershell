Function Set-DRSAutomationLevel{
     param(
         [Parameter(Mandatory=$true, Position=0)][String]$vm,
         [Parameter(Mandatory=$true, Position=1)][ValidateSet('fullyAutomated','manual','partiallyAutomated','disabled','default')][String]$DRSAutomationLevel
      )
     Try
     {
       $vm_view = Get-View -ViewType VirtualMachine -Filter @{"Name" = $vm}
       $cluster_view = get-view (get-view $vm_view.Runtime.Host).Parent
       $operation = "add"
       Foreach($guest in $cluster_view.ConfigurationEx.DrsVmConfig | Where {$_.Key.Value -eq $vm_view.MoRef.Value}) {
           if ($DRSAutomationLevel -like "default") {
              # remove the custom DRS setting for that VM
              $operation = "remove"
           } else {
              $operation = "edit"
           }
        }
  
  
       if (($DRSAutomationLevel -like "default") -and ($operation -like "add")) {
            # if there is no VM specific DRS setting - do nothing
       }else {
            $spec = New-Object VMware.Vim.ClusterConfigSpec
            $VMspec = New-Object VMware.Vim.ClusterDrsVmConfigSpec
            $VMspec.operation = $operation
            $VMspec.Info = New-Object VMware.Vim.ClusterDrsVmConfigInfo
            if ($DRSAutomationLevel -like "disabled"){
                 $VMspec.Info.Enabled = $false
                 $VMspec.Info.Key = $vm_view.MoRef
            }elseif ($DRSAutomationLevel -like "default"){
                 $VMspec.removeKey = $vm_view.MoRef
            }else {
                 $VMspec.Info.Enabled = $true
                 $VMspec.Info.Behavior = $DRSAutomationLevel
            }
  
            $VMspec.Info.Key = $vm_view.MoRef
            $spec.DrsVmConfigSpec = @($VMspec)
            $cluster_view.ReconfigureCluster($spec, $true)
       }
         Return $True
      }
      Catch
      {
         Return $False  
      }
}

Function Set-SDRSAutomationLevel{
   param(
      [Parameter(Mandatory=$true, Position=0)][String]$vm,
      [Parameter(Mandatory=$true, Position=1)][ValidateSet('automated','manual','disabled','default')][String]$SDRSAutomationLevel
   )
   Try
   {
      $vm_view = Get-View -ViewType VirtualMachine -Filter @{"Name" = $vm}
      $pod=get-view (get-view $vm_view.Datastore).Parent
      $operation = "add"

      Foreach($guest in $pod.PodStorageDrsEntry.StorageDrsConfig.VmConfig | Where {$_.VM.Value -eq $vm_view.MoRef.Value}) 
      {
         If ($SDRSAutomationLevel -like "default")
         {
            # remove the custom DRS setting for that VM
            $operation = "remove"
         } 
         else 
         {
            $operation = "edit"
         }
      }

     if (($SDRSAutomationLevel -like "default") -and ($operation -like "add")) {
          # if there is no VM specific DRS setting - do nothing
     }else {
            $spec = New-Object VMware.Vim.StorageDrsConfigSpec
          	$VMspec = New-Object VMware.Vim.StorageDrsVmConfigSpec
          	$VMspec.operation = $operation
            $VMspec.Info = New-Object VMware.Vim.StorageDrsVmConfigInfo
            $VMspec.Info.VM = $vm_view.MoRef
             if ($SDRSAutomationLevel -like "disabled"){
                 $VMspec.Info.Enabled = $false
            }elseif ($SDRSAutomationLevel -like "default"){
                 $VMspec.removeKey = $vm_view.MoRef
            }else {
                 $VMspec.Info.Enabled = $true
                 $VMspec.Info.Behavior = $SDRSAutomationLevel
            }
            $VMspec.Info.VM = $vm_view.MoRef            
            $spec.vmConfigSpec += $VMspec
          	$SRM = Get-View StorageResourceManager 
          	$SRM.ConfigureStorageDrsForPod($pod.moref, $spec, $true)
     }
   Return $True
   }
   Catch
   {
      $ErrorMessage = $_.Exception.Message
      write-host  $ErrorMessage
      Return $False
   }
   
}