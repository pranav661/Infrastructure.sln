Write-Host "Starting Deployment"

$Env = "dev"

$resourcegroups = @{
  "AppServiceResourceGroup" = "web-rg"
  "StorageAccountResourceGroup" = "storage-rg"
  "DemoResourceGroup" = "newfreeresources-rg"
 }


 function replace_parameters_and_deploy_storage {
 Param ($resgrp,$newstoragename,$template,$parameters)

  foreach ($resources in $resourcegroups.GetEnumerator()) 
   {

     if($resources.key -contains $resgrp)
      {
         $ResourceGroup = $resources.value  
      }
   }
 
  #echo $ResourceGroup
 
  $randomstring = ([char[]] ([char[]]([char]97..[char]122)) + 0..9 | sort {Get-Random})[0..4] -join ''
  #echo "${randomstring}" 

  $StorageName = "${Env}" + $newstoragename + "${randomstring}"
  #echo $StorageName

  Write-Host ("Template location is {0}" -f "${template}")

  $json_data = Get-Content "${parameters}" | ConvertFrom-Json
  $json_data.parameters.storageAccountName.value = "${StorageName}"
  
  $json_data | ConvertTo-Json | Set-Content $parameters

  New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $template -TemplateParameterFile $parameters

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

   #Write-Host ("{0} has value {1}" -f $resources.key, $resources.value)
   $AvailableResource = Get-AzureRmResource -ResourceType "Microsoft.Storage/storageAccounts" | Where-Object {$_.Name -match $resources.value}

   if(!($AvailableResource))
   {
      #Write-Host $resources.value
      #Write-Host "Resource does not Exists"
      replace_parameters_and_deploy_storage -resgrp $ResGrpType -newstoragename $resources.value -template $Template_file -parameters $Parameter_file
   }
  }
 
  #Write-Host ("Template location is {0}" -f "${Template_File}")
 }

$tempappservice = "C:\POCS\Infrastructure\Templates\App_Service"
$tempstoracc = "C:\POCS\Infrastructure\Templates\Storage_Account"

#app_service -template_loc $tempappservice
storage_account -template_loc "${tempstoracc}"