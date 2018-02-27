function Set-VMConfiguration {
  <#
      .Synopsis
          Change VM configuration
      
      .DESCRIPTION
          Set New Configuration for VM
      
      .PARAMETER VMList
          List of VM Name to change configuration
      
      .PARAMETER GuestId
          Target OS GuestId
          See http://www.fatpacket.com/blog/2016/12/vm-guestos-identifiers/ 
          
      .PARAMETER HWVersion
          Target Virtual Hardware
          
      .PARAMETER CPUHotAdd
          True if CPUHotAdd should be activated
          False if it does not       
          
      .EXAMPLE
          Set-VMConfiguration -VM <VM1>,<VM2> -GuestID rhel7_64Guest -HWVersion v11     
                    
      .OUTPUTS
          Boolean
          
      .Notes
          Author: Vincent Gitton
  #>
  [CmdletBinding()]
      Param
      (
          [Parameter(Mandatory)]
          [string[]]$VMList,
          [Parameter(Mandatory=$false)][ValidateSet('rhel6_64Guest','rhel7_64Guest','windows9Server64Guest','windows8Server64Guest','windows7Server64Guest')]
          [string]$GuestId,
          [Parameter(Mandatory=$false)][ValidateSet('v9','v11')]
          [string]$HWVersion,
          [Parameter(Mandatory=$false)][ValidateSet('True','False')]
          [String]$CPUHotAdd,
          [switch]$Force
      ) 
  Try
  {   
    Write-Output "Starting script"
    Write-Output "$($VMList.count) VM loaded"
    If ($Force)
    {
      $message  = 'Force Mode activated, VM will be stopped if they are running'
      $question = 'Are you sure you want to proceed?'
      $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
      $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
      $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))
      $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)
    }Else
    {
      $decision = 0
    }
    if ($decision -eq 0) {
      Foreach ($VM in $VMList)
      {
        If ($Flag){Remove-Variable flag}
        If ($TheVM = Get-VM -Name $VM)
        {
           If ($TheVM.PowerState -eq "PoweredOn")
           {
              If ($Force)
              {
                 Write-Warning "$($TheVM.Name) : State is PoweredOn and Reconfiguration is forced. Stopping GuestOS"
                 $Flag = Stop-VMGuestForce -VMList $TheVM.Name
              }Else
              {
                 Write-Warning "$($TheVM.Name) : State is PoweredOn and Reconfiguration is not forced. Skipping"
                 Continue;
              }   
           }
            If ($HWVersion)
            {
               Write-Output "$($TheVM.Name) : Reconfigure Hardware Version"
               $Task = $TheVM | Set-VM -Version $HWVersion -Confirm:$false -RunAsync
               $TaskResult = Wait-Task $task   
            }
            If ($GuestID)
            {
               Write-Output "$($TheVM.Name) : Reconfigure GuestId"
               $Task = $TheVM | Set-VM -GuestId $GuestID -Confirm:$false -RunAsync
               $TaskResult = Wait-Task $task   
            }
            If ($CPUHotAdd)
            {
               Write-Output "$($TheVM.Name) : Reconfigure vCPU Hot Add"
               $vmView = Get-View $TheVM
               $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
               $extra = New-Object VMware.Vim.optionvalue
               $extra.Key="vcpu.hotadd"
               If ($CPUHotAdd -eq $False)
               {
                  $extra.Value="false"
               }Else
               {
                  $extra.Value="true"
               }
               $vmConfigSpec.extraconfig += $extra
               $vmview.ReconfigVM($vmConfigSpec)
               
            }
            If ($Flag)
            {
               Write-Output "$($TheVM.Name) : Restarting VM"
               $Task = Start-VM $TheVM -RunAsync
               $TaskResult = Wait-Task $task  
            }
           
        }Else
        {
           Write-Error "$($VM) : does not exist"
        }
      }
      Return $true
   }Else{
      Write-Error "Script cancelled"  
   }
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
