function Get-VNXLunUsage {
  <#
      .Synopsis
          Get VNX real Lun consummed
      
      .DESCRIPTION
          Get VNX real Lun consummed
      
      .PARAMETER ArrayList
          List of Array you want to collect lun real usage
      
      .PARAMETER NaviCli
          NaviSeccli binary path
          
      .PARAMETER Pattern
          Pattern of desired lun. Leave empty no filter is needed

      .EXAMPLE
          Get-VNXLunUsage -ArrayList <Array1>,<Array2> -LunPattern "LUN_SYS"     
                    
      .OUTPUTS
          PSCustomObject
          
      .Notes
          Author: Vincent Gitton
  #>
  [CmdletBinding()]
      Param
      (
          [Parameter(Mandatory)]
          [string[]]$ArrayList,
          [Parameter(Mandatory=$false)]
          [string]$Navicli = "C:\Program Files (x86)\EMC\Navisphere CLI\NaviSECCli.exe",
          [Parameter(Mandatory=$false)]
          [string]$LunPattern
      ) 
  Try
  {
      Write-Output "Starting Script" 
      $LunList = @()
      Foreach ($Array in $ArrayList)
      { 
         Write-Output "VNX Array $($Array)"
         $Luns = (& $Navicli -h $Array lun -list | Select-String "^Name:  " | Select-String "$($LunPattern)")
         Write-Output "$($Luns.count) luns identified"
         $luns | %{
               $Row = "" | Select Array,Name,Size
               $Row.Array = $Array
               $Row.name = ($_ -split " ")[2]
               $Row.Size = (((& $Navicli -h $Array lun -list -name $Row.name -consumedCap) |Select-string "Consumed Capacity \(GBs\):") -split("  "))[1]
               $LunList += $Row
            }
      }
      Return $LunList
  }Catch
  {
     $ErrorMessage = $_.Exception.Message
      Write-Error $ErrorMessage
      Write-Error $_.invocationinfo.scriptlinenumber
      Return $false
    }
  Finally
  {
   Write-Output "End Of Script" 
  }
}
