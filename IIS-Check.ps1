<#

  Version:        0.2
  Author:         Anil D'Souza
  Creation Date:  6/13/2019
  Modified Date:  6/14/2019
  Purpose/Change: Log snapshot of key features of IIS 
                  and Windows Services pre/post upgrade of Time
                  to help verify/troubleshoot configuration 
  Version History: 
  0.1  Initial Create Date 
  0.2  $AppPoolProperties += $Properties was creating a "duplicate collection entry of type '..." on client's server 
                 
#>

$filepath = "C:\Temp\"
$filename = "Intapp_Time_log_" + (get-date -Format "MM-dd-yyyy_hh_mm_ss") + ".txt" 

$log = $filepath + $filename 

CLS

$env:computername

#$computers = Import-Csv “D:\PowerShell\computerlist.csv”
$computers = $env:computername
$array = @()

foreach($pc in $computers){

    $computername=$pc

    #Define the variable to hold the location of Currently Installed Programs

    $UninstallKey=”SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall” 

    #Create an instance of the Registry Object and open the HKLM base key

    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey(‘LocalMachine’,$computername) 

    #Drill down into the Uninstall key using the OpenSubKey Method

    $regkey=$reg.OpenSubKey($UninstallKey) 

    #Retrieve an array of string that contain all the subkey names

    $subkeys=$regkey.GetSubKeyNames() 

    #Open each Subkey and use GetValue Method to return the required values for each

    foreach($key in $subkeys){

        $thisKey=$UninstallKey+”\\”+$key 

        $thisSubKey=$reg.OpenSubKey($thisKey) 

        $obj = New-Object PSObject

        $obj | Add-Member -MemberType NoteProperty -Name “ComputerName” -Value $computername

        $obj | Add-Member -MemberType NoteProperty -Name “DisplayName” -Value $($thisSubKey.GetValue(“DisplayName”))

        $obj | Add-Member -MemberType NoteProperty -Name “DisplayVersion” -Value $($thisSubKey.GetValue(“DisplayVersion”))

        $obj | Add-Member -MemberType NoteProperty -Name “InstallLocation” -Value $($thisSubKey.GetValue(“InstallLocation”))

        $obj | Add-Member -MemberType NoteProperty -Name “Publisher” -Value $($thisSubKey.GetValue(“Publisher”))

        $array += $obj

    } 

}

$array | Where-Object { $_.DisplayName } | 
select ComputerName, DisplayName, DisplayVersion, Publisher, InstallLocation | 
where-object DisplayName -like Intapp*Time* |
ft -auto > $log 

Import-Module webadministration

$AppPoolProperties = @()

foreach ( $pool in (get-item IIS:\AppPools\*) ) {

$Properties = New-Object System.Object

$Properties | Add-Member -type NoteProperty -name AppPoolName `
    -Value $($pool.name)

$Properties | Add-Member -type NoteProperty -name Enable32bit `
    -Value $($pool.enable32BitAppOnWin64)

$Properties | Add-Member -type NoteProperty -name Runtime `
    -Value $($pool.managedRuntimeVersion)

$Properties | Add-Member -type NoteProperty -name Pipeline `
    -Value $($pool.managedPipelineMode)

$Properties | Add-Member -type NoteProperty -name ProcessModel `
    -Value $($pool | Get-ItemProperty -name processModel.identityType)

# version 0.2 writing straight to log file 
$Properties | Select AppPoolName, Enable32bit, Runtime, Pipeline, ProcessModel |ft -auto | Out-File -Append $log

#$AppPoolProperties += $Properties
}

#$AppPoolProperties | Select AppPoolName, Enable32bit, Runtime, Pipeline, ProcessModel |ft -auto | Out-File -Append $log 

Get-ItemProperty IIS:\AppPools\* |ft -auto | Out-File -Append $log 

Get-Website |ft -auto | Out-File -Append $log 


$websites = Get-Website 
foreach ($website in $websites.Name)
{
    $value = Get-WebConfigurationProperty -Filter "//defaultDocument/files/add" -PSPath "IIS:\Sites\$website" -Name "value" | select value
    $str = $value | Out-String  
    $str.Replace("Value","$website Default Document Property") | Out-File -Append $log 
     

}

"Current Snapshot of Windows Services" | Out-File -Append $log 
Get-Service |ft -auto | Out-File -Append $log 


write-Host "`n$filename written to $filepath.  `nPress Enter to exit."
notepad $log 