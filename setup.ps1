Import-Module .\modules\VDFSerialization.psm1

$LaunchOptions = "-novid -nojoy -high -language textmod -refresh 144"
$CfgFiles = "autoexec.cfg", "autoexec", "training.cfg"

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

  $Cfg = Join-Path -Path $folder.FullName -ChildPath "730\local\cfg"
  #create empty folder structure if not present
  New-Item -Type Directory $Cfg -Force | Out-Null
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

    New-Item -ItemType SymbolicLink -Name $path -Path $Cfg -Value "$($Src.FullName)\$path" | Out-Null
  }
}

# $LibraryFolders = Join-Path -Path $SteamPath -ChildPath "steamapps\libraryfolders.vdf"
# $Librarys = ConvertFrom-VDF -InputObject (Get-Content $LibraryFolders)

# #Search the CSGO Folder
# $csgo = [string]::Empty

# for ($i = 1; $true; $i++) {
#   if ($null -eq $Librarys.LibraryFolders."$i") {
#     break
#   }

#   $tmpPath = Join-Path -Path $Librarys.LibraryFolders."$i".Replace("\\","\") -ChildPath "steamapps\common\Counter-Strike Global Offensive\csgo"

#   if (Test-Path $tmpPath) {
#     $csgo = $tmpPath
#     break
#   }
# }

# if ($csgo -eq [string]::Empty) {
#   Write-Error "Could not find csgo, is it installed?" -ErrorAction Stop
# }

#TODO: Look for config in global directory and delete it.