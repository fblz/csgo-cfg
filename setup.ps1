Set-StrictMode -Version latest
$ErrorActionPreference = 'Stop'

filter SePriv {(-split $_)[0]}
if (-not (whoami /priv /FO TABLE /NH | SePriv).Contains("SeCreateSymbolicLinkPrivilege")) {
  Write-Error "This script uses symbolic links which you cannot create. Either run as Administrator or enable developer mode."
}

Import-Module .\modules\VDFSerialization.psm1

$LaunchOptions = "-novid -nojoy -high -language textmod -refresh 144"
$CfgFiles = Get-ChildItem .\src\ | Select-Object -ExpandProperty Name

$SteamPath = Get-Item ((Get-Item HKCU:\Software\Valve\Steam\).GetValue("SteamPath").Replace("/","\"))
$Userdata = Get-Item (Join-Path -Path $SteamPath -ChildPath "userdata")

foreach ($folder in (Get-ChildItem -Directory $Userdata)) {
  $File = Join-Path -Path $folder.FullName -ChildPath "config\localconfig.vdf"
  $Config = ConvertFrom-VDF -InputObject (Get-Content $File)

  if ($null -eq $Config.UserLocalConfigStore.Software.Valve.Steam.apps."730") {
    Write-Host "No CSGO in $($Config.UserLocalConfigStore.friends.PersonaName)s Library."
    continue
  }

  Write-Host "Install LaunchOptions and Autoexec to $($Config.UserLocalConfigStore.friends.PersonaName)s Account? (Y/n)" -NoNewline
  $userInput = Read-Host
  if ($userInput -like "n") {
    continue
  }

  Add-Member -InputObject $Config.UserLocalConfigStore.Software.Valve.Steam.apps."730" -MemberType NoteProperty -Name "LaunchOptions" -Value $LaunchOptions -Force
  ConvertTo-VDF -InputObject $Config | Out-File -NoNewline -Encoding utf8 -FilePath $File

  $CfgDirectory = Join-Path -Path $folder.FullName -ChildPath "730\local\cfg"
  #create empty folder structure if not present
  New-Item -Type Directory $CfgDirectory -Force | Out-Null
  $Src = Get-Item .\src

  foreach ($item in Get-ChildItem $CfgDirectory) {
    if ($item.Target)
    {
      Remove-Item $item
    }
    elseif ($CfgFiles.Contains($item.Name)) {
      Remove-Item -Recurse $item
    }
  }

  foreach ($name in $CfgFiles) {
    New-Item -ItemType SymbolicLink -Name $name -Path $CfgDirectory -Value "$($Src.FullName)\$name" | Out-Null
  }
}