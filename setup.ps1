Import-Module .\modules\VDFSerialization.psm1

$File = Get-Content .\localconfig.vdf
$Config = ConvertFrom-VDF -InputObject $File

$LaunchOptions = "-novid -nojoy -nod3d9ex -high -language textmod"

if ($Config.UserLocalConfigStore.Software.Valve.Steam.apps."730" -ne $null) {
  $Config.UserLocalConfigStore.Software.Valve.Steam.apps."730".LaunchOptions = $LaunchOptions
} else {
  Write-Error "Could not find CSGO in localconfig. LaunchOptions unchanged."
}

$NewFile = ConvertTo-VDF -InputObject $Config
$NewFile | Out-File -NoNewline -Encoding utf8 .\localconfig.vdf