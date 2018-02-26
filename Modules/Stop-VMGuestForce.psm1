function Stop-VMGuestForce {
  <#
      .Synopsis
          Stop VM via GuestOS, Then Force  
      
      .DESCRIPTION
          Try to stop GuestOS of VM provide in VMlist. If it stucks, force using VM-Stop
      
      .PARAMETER VMList
          List of VM Name to Stop
        
      .EXAMPLE
          Stop-VMGuestForce -VMList <VM1>,<VM2>     
                    
      .OUTPUTS
          Boolean
          
      .Notes
          Author: Vincent Gitton
  #>
  [CmdletBinding()]
      Param
      (
          [Parameter(Mandatory)]
          [string[]]$VMList
      ) 
  Try
  {   
    Write-Output "Starting script"
    Write-Output "$($VMList.count) VM loaded"
    Foreach ($vm in $VMList)
    {
      $TheVM = Get-VM $VM
      If ($TheVM.PowerState -eq "PoweredOn")
      {
         If ($TheVM.Guest.State -eq "Running")
         {
            Write-Output "$($TheVM) : Guest Stopping VM"
            $Task = Stop-VMGuest -VM $TheVM -Confirm:$false
            $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
            Do{
               Start-Sleep -s 20 
            }Until(((Get-VM $TheVM).powerstate -eq "PoweredOff") -Or ($stopwatch.Elapsed.TotalMinutes -gt 5))     
            If ((get-vm $VM).PowerState -ne "PoweredOff")
            {
               Write-warning "$($TheVM) : Cannot stop GuestOS, Force"
               $task = Stop-VM -VM $vm -confirm:$false -RunAsync
               $TaskResult = Wait-Task $task   
            }
            $stopwatch.Stop()
            $stopwatch.Reset()
         }Else{
            Write-warning "$($TheVM) : VMtools not running, Stop VM"
            $task = Stop-VM -VM $vm -confirm:$false -RunAsync
            $TaskResult = Wait-Task $task      
         }
      }Else
      {
         Write-Warning "$($TheVM.name) : VM is not running, Skipping." 
      }     
   }
   Return $True
  }Catch
  {
    $ErrorMessage = $_.Exception.Message
    Write-Error $ErrorMessage
    Write-Error $_.invocationinfo.scriptlinenumber
    Return $false
  }Finally
  {
   Write-Output "End Of Script" 
  }
}
