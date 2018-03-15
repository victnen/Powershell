 <#   
  .Synopsis   
   Imports roles into vsphere roles..   
  .Description   
   This script imports roles into vspheres from .role file/   
  .Example   
   Import-vSphereRoles -Path c:\temp  
   Import Roles to the folder.   
  .Notes  
   NAME: Import-vSphere Roles    
   KEYWORDS: Import Roles     
  #>    
 [CmdletBinding(SupportsShouldProcess)]   
  Param(   
   [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]   
   [AllowNull()]   
   [alias("LiteralPath")]   
   [string]$RoleFile = "c:\temp"    
  ) #Param   
 Begin {  
   $authMgr = Get-View AuthorizationManager
   $vInventory = [xml]“<dummy/>”
   $vInventory.Load($RoleFile)
   $XpathRoles = “Inventory/Roles/Role”
   $XpathPermissions = “Inventory/Permissions/Permission”  
 }  
 Process { 
 
   Write-Host "Creating roles on Vcenter"
   Foreach ($role in $vInventory.SelectNodes($XpathRoles) | Where {$_.Name -notin $authMgr.RoleList.Name})
   {
      $privArray = @()
      Foreach ($privilege in $role.privilege | Where {$_.Name -ne "Host.Local.RelayoutSnapshots" -And $_.Name -ne "Host.Local.ExtractNvramContent"})
      {
         
         $privArray += Get-VIPrivilege -Id $privilege.name
      }
      New-VIRole -Name $Role.Name -Privilege $privArray | Out-Null
      #Set-VIRole -Role $Role.Name -AddPrivilege $privArray | Out-Null
   }
   Write-Host "Applying permissions"
   Foreach ($i in $vInventory.SelectNodes($XpathPermissions))
   {
      $EntityName = $i.Entity.Replace(“(“,“\(“).Replace(“)”,“\)”)
      $EntityName = $EntityName.Replace(“[","\[").Replace("]“,“\]”)
      $EntityName = $EntityName.Replace(“{“,“\{“).Replace(“}”,“\}”)
      if ($i.Propagate -eq "True")
      {$propagation = $true}Else{$propagation = $false}
      If ($i.EntityType -eq "Datacenter")
      {
         $ent = get-datacenter -name $EntityName
      }ElseIf($i.EntityType -eq "Folder")
      {
         $ent = Get-Folder -name $EntityName   
      }
      $perm = New-VIPermission -Role (Get-VIRole -Name $i.Role) -Principal $i.Principal -Entity $ent -Propagate:$propagation -Confirm:$false   
   }
 }  