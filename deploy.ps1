param(
 [Parameter(Mandatory=$True)]
 [string]$Envt,
 
 [Parameter(Mandatory=$True)]
 [string]$AppServiceParamLoc,
 
 [Parameter(Mandatory=$True)]
 [string]$StorAccParamLoc
 )

Write-Host "Starting Deployment"

#$Env = "dev"
Write-Host $Envt

$resourcegroups = @{
  "AppServiceResourceGroup" = "web-rg"
  "StorageAccountResourceGroup" = "storage-rg"
  "DemoResourceGroup" = "newfreeresources-rg"
 }

 function replace_parameters_and_deploy_storage {
 Param ($resgrp,$newstoragename,$template,$parameters)
Write-Host "inside area 3"
  foreach ($resources in $resourcegroups.GetEnumerator()) 
   {
     if($resources.key -contains $resgrp)
      {
         $ResourceGroup = $resources.value  
      }
   }
 
  $randomstring = ([char[]] ([char[]]([char]97..[char]122)) + 0..9 | sort {Get-Random})[0..4] -join ''

  $StorageName = "${Envt}" + $newstoragename + "${randomstring}"
  Write-Host $StorageName

  Write-Host ("Template location is {0}" -f "${template}")

  $json_data = Get-Content "${parameters}" | ConvertFrom-Json
  $json_data.parameters.storageAccountName.value = "${StorageName}"
  
  $json_data | ConvertTo-Json | Set-Content $parameters
  
  Write-Host $parameters

  #New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $template -TemplateParameterFile $parameters

 }
  

function app_service {
Param ($Template_Loc)
 Write-Host "App Service will be getting deployed"

 $randomstring = ([char[]] ([char[]]([char]97..[char]122)) + 0..9 | sort {Get-Random})[0..4] -join ''
 echo "${randomstring}"

 $Template_file = "${Template_Loc}" + "\" + "template.json"
 $Parameter_file = "${Template_Loc}" + "\" + "parameters.json"
 Write-Host ("Template location is {0}" -f "${Template_File}")
}


function storage_account {
 Param ($Template_Loc)
 Write-Host "Storage Account will be getting deployed"
 
 $ResGrpType = "DemoResourceGroup"

 $Template_file = "${Template_Loc}" + "\" + "template.json"
 $Parameter_file = "${Template_Loc}" + "\" + "parameters.json"

 $storageaccounts = @{
  "tempaccountStorageAccountName" = "tempaccount"
  "testaccountStorageAccountName" = "testaccount"
 }

 foreach ($resources in $storageaccounts.GetEnumerator()) 
  {
  Write-Host "inside area 1"
   $AvailableResource = Get-AzureRmResource -ResourceType "Microsoft.Storage/storageAccounts" | Where-Object {$_.Name -match $resources.value}
   if(!($AvailableResource))
   {
   Write-Host "inside area 2"
      replace_parameters_and_deploy_storage -resgrp $ResGrpType -newstoragename $resources.value -template $Template_file -parameters $Parameter_file
   }
  }
 }

#app_service -template_loc $AppServiceParamLoc
storage_account -template_loc "${StorAccParamLoc}"
