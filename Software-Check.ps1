

$ErrorActionPreference = ‘SilentlyContinue’

$computerOS = Get-CimInstance CIM_OperatingSystem 
$computerSystem = Get-CimInstance CIM_ComputerSystem 

$IISVersionString = "" 
     
    $IISVersionString = ((reg query \\$($computerSystem.Name)\HKLM\SOFTWARE\Microsoft\InetStp\ | findstr VersionString).Replace(" ","")).Replace("VersionStringREG_SZ","") 
 
    if ($IISVersionString -eq ""){ 
 
        $IISVersionString = "Not Installed." 
     
    } 
 
    $results = [PSCustomObject]@{ 
     
        ServerName = $machine 
        IISVersion = $IISVersionString 
        Pingable = $pingstate 
 
    } 

   # Microsoft Visual C++ 2015 Redistributable (x86) - 14.0.24215

   # WMIC /node:"ANILD" 

#WMIC product where name="Microsoft Visual C++ 2008 Redistributable"
 

    
$NET_Version = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | Get-ItemProperty -name Version -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select -First 1 | %{ $_.Version }

$wcf_HTTP = Get-WindowsFeature -name NET-WCF-HTTP-Activation45 -erroraction 'silentlycontinue'
$wcf_MSMQ = Get-WindowsFeature -name NET-WCF-MSMQ-Activation45 -erroraction 'silentlycontinue'
$MSMQFeature =  Get-WindowsFeature -name MSMQ-Services -erroraction 'silentlycontinue'
$Unauthenticated_RPC = [string](Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSMQ\Parameters\security -erroraction 'silentlycontinue' ).AllowNonauthenticatedRpc 
$ASPNET35 = Get-WindowsFeature -name Web-Asp-Net -erroraction 'silentlycontinue'
$ASPNET45 = Get-WindowsFeature -name Web-Asp-Net45 -erroraction 'silentlycontinue'
$WindowsAuthentication = Get-WindowsFeature -name Web-Windows-Auth -erroraction 'silentlycontinue'
$DefaultDocument = Get-WindowsFeature -name Web-Default-Doc -erroraction 'silentlycontinue'
$BasicAuthentication = Get-WindowsFeature -name Web-Basic-Auth  -erroraction 'silentlycontinue'
$Performance = Get-WindowsFeature -name Web-Stat-Compression -erroraction 'silentlycontinue'
$Static_Content = Get-WindowsFeature -name Web-Static-Content -erroraction 'silentlycontinue'
$Directory_Browsing = Get-WindowsFeature -name Web-Dir-Browsing 


Clear-Host

Write-Host "Intapp Software Check" -BackgroundColor DarkCyan
Write-Host "System Information for: " $computerSystem.Name -BackgroundColor DarkCyan
"Highest .NET version installed: " + $NET_Version 
"Operating System: " + $computerOS.caption + ", Service Pack: " + $computerOS.ServicePackMajorVersion
"IIS " + $results.IISVersion.Replace("Version","Version: ") 
"IIS WCF HTTP: " + $wcf_HTTP.Installed
"IIS WCF MSMQ: " + $wcf_MSMQ.Installed
"Microsoft Message Queue (MSMQ): " + $MSMQFeature.Installed 
"Un-authenticated RPC calls: " + ($Unauthenticated_RPC.Replace("1","True")).Replace("0","False")
"IIS ASP.NET 3.5: " + $ASPNET35.Installed  
"IIS ASP.NET 4.x: " + $ASPNET45.Installed 
"IIS Windows Authentication: " + $WindowsAuthentication.Installed 
"IIS Default Document: " + $DefaultDocument.Installed  
"IIS Basic Document: " + $BasicAuthentication.Installed  
"IIS Performance Compression: " + $Performance.Installed
"IIS Static Content: " + $Static_Content.Installed 
"IIS Directory Browsing: " + $Directory_Browsing.installed
"Microsoft Visual C++ Distributables installed: " 
#####Get-WmiObject Win32_product | Where-Object {$_.name -like "Microsoft Visual C++*"} | select name 
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "Microsoft Visual C++*"} |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | 
Format-Table –AutoSize

"Internet Connectivity: " 
Test-NetConnection -InformationLevel Detailed

"Testing SCP Port 8080 on $($computerSystem.Name): " 
Test-NetConnection -ComputerName $computerSystem.Name -Port 8080  -InformationLevel "Detailed"

" Does command need to be run : netsh http add urlacl url=http://+:8080/ user=""Network Service""  ?"
netsh http show urlacl url=https://+:8080/ 



