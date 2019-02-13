Import-Module .\modules\VDFSerialization.psm1

$LaunchOptions = "-novid -nojoy -high -language textmod -refresh 144"
$CfgFiles = "autoexec.cfg", "autoexec", "scripts"
$SimpleRadar = "http://simpleradar.com/downloads/fullpackV2.zip"

$SteamPath = Get-Item ((Get-Item HKCU:\Software\Valve\Steam\).GetValue("SteamPath").Replace("/","\"))
$Userdata = Get-Item (Join-Path -Path $SteamPath -ChildPath "userdata")

foreach ($folder in (Get-ChildItem -Directory $Userdata)) {
  $File = Join-Path -Path $folder.FullName -ChildPath "config\localconfig.vdf"
  $Config = ConvertFrom-VDF -InputObject (Get-Content $File)

  if ($null -ne $Config.UserLocalConfigStore.Software.Valve.Steam.apps."730".LaunchOptions) {
    $Config.UserLocalConfigStore.Software.Valve.Steam.apps."730".LaunchOptions = $LaunchOptions
  } elseif ($null -ne $Config.UserLocalConfigStore.Software.Valve.Steam.apps."730") {
    Add-Member -InputObject $Config.UserLocalConfigStore.Software.Valve.Steam.apps."730" -MemberType NoteProperty -Name "LaunchOptions" -Value $LaunchOptions
  } else {
    Write-Error "Could not find CSGO in $($folder.Name) localconfig. LaunchOptions unchanged."
    continue
  }

  ConvertTo-VDF -InputObject $Config | Out-File -NoNewline -Encoding utf8 -FilePath $File
}

$LibraryFolders = Join-Path -Path $SteamPath -ChildPath "steamapps\libraryfolders.vdf"
$Librarys = ConvertFrom-VDF -InputObject (Get-Content $LibraryFolders)

#Search the CSGO Folder
$csgo = [string]::Empty

for ($i = 1; $true; $i++) {
  if ($null -eq $Librarys.LibraryFolders."$i") {
    break
  }

  $tmpPath = Join-Path -Path $Librarys.LibraryFolders."$i".Replace("\\","\") -ChildPath "steamapps\common\Counter-Strike Global Offensive\csgo"

  if (Test-Path $tmpPath) {
    $csgo = $tmpPath
    break
  }
}

if ($csgo -eq [string]::Empty) {
  Write-Error "Could not find csgo, is it installed?" -ErrorAction Stop
}

$temp = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "csgo-cfg-installer"
mkdir $temp | Out-Null
$Overviews = Join-Path -Path $csgo -ChildPath "resource\overviews"

Invoke-WebRequest -Uri $SimpleRadar -OutFile "$temp\radar.zip"
Expand-Archive -Path "$temp\radar.zip" -DestinationPath $Overviews -Force
Remove-Item -Path ("$temp\radar.zip", $temp, "$Overviews\read-me.txt")
Remove-Item -Path "$Overviews\de_cache_radar_spectate.dds" -ErrorAction SilentlyContinue

$Resource = Join-Path $csgo "resource"
Copy-Item .\src\csgo_textmod.txt $Resource -Force

$Cfg = Join-Path $csgo "cfg"
$Src = Get-Item .\src

foreach ($path in $CfgFiles) {
  $item = Get-Item "$Cfg\$path" -ErrorAction SilentlyContinue

  if ($null -ne $item) {
    if (-not $item.Target) {
      Remove-Item -Recurse $item
    } elseif ($item.Target[0].Contains($Src.FullName)) {
      continue
    }
  }

  New-Item -ItemType SymbolicLink -Name $path -Path $Cfg -Value ".\src\$path" | Out-Null
}