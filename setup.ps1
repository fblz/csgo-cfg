Import-Module .\modules\VDFSerialization.psm1

$LaunchOptions = "-novid -nojoy -nod3d9ex -high -language textmod"
$SimpleRadar = "http://simpleradar.com/downloads/fullpackV2.zip"

$SteamPath = (Get-Item HKCU:\Software\Valve\Steam\).GetValue("SteamPath").Replace("/","\")
$Userdata = Join-Path -Path $SteamPath -ChildPath "userdata"

foreach ($folder in (Get-ChildItem -Directory $Userdata)) {
  $File = Join-Path -Path $folder.FullName -ChildPath "config\localconfig.vdf"
  $Config = ConvertFrom-VDF -InputObject (Get-Content $File)

  if ($Config.UserLocalConfigStore.Software.Valve.Steam.apps."730".LaunchOptions -ne $null) {
    $Config.UserLocalConfigStore.Software.Valve.Steam.apps."730".LaunchOptions = $LaunchOptions
  } elseif ($Config.UserLocalConfigStore.Software.Valve.Steam.apps."730" -ne $null) {
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
  if ($Librarys.LibraryFolders."$i" -eq $null) {
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
Remove-Item -Recurse -Force -Path ("$Cfg\autoexec.cfg", "$Cfg\autoexec", "$Cfg\scripts") -ErrorAction SilentlyContinue
Copy-Item -Recurse -Path (".\src\autoexec",".\src\scripts",".\src\autoexec.cfg") -Destination $Cfg