param (
    [Parameter(Mandatory=$true)]
    [string] $File,
    [float]  $FPSMultiplier = 0.1, # default 1/10 of the speed
    [switch] $Force,
    [switch] $Cache
)

$ErrorActionPreference = "Stop"


if (-not $(Test-Path -Path $File)) {
    Write-Error "$File does not exist"
    return 2
}
$FileObj = Get-Item $File

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$ExtractJPEGExe = Join-Path $ScriptPath "ExtractJPEGcmd.exe"

if (-not $(Test-Path -Path $ExtractJPEGExe)) {
    Write-Error "$ExtractJPEGExe does not exist"
    return 2
}

$BaseName = $FileObj.BaseName
$OutPath = Join-Path $ScriptPath "_$BaseName"
$OutFilePrefix = "sceye"
$FullPrefix = Join-Path $OutPath $OutFilePrefix

New-Item -ItemType Directory -Path $OutPath -Force | Out-Null
if (-not $Force -and $(Test-Path "$FullPrefix*")) {
    Write-Error "$OutPath contains files that start with `"$OutFilePrefix`", thus may be overwritten. Use -Force to overwrite any existing files."
    return 17
}

Write-Output "Extracting jpg files..."
& $ExtractJPEGExe $File $FullPrefix

Write-Output "Getting metadata..."
$Bytes = [System.IO.File]::ReadAllBytes($FileObj)

$JSONOffsetStart = 16
if ($Bytes[$JSONOffsetStart] -ne [byte][char]'{') {
    $Header = [System.Text.Encoding]::ASCII.GetString($Bytes, 0, $JSONOffsetStart + 1)
    Write-Error "$File starts with '$Header' <= '{' expected"
    return 11
}

for ($JSONOffsetEnd = $JSONOffsetStart + 1; $JSONOffsetEnd -lt $Bytes.Length; $JSONOffsetEnd++) {
    if ($Bytes[$JSONOffsetEnd] -eq [byte][char]'}') {
        break;
    }
}
if ($JSONOffsetEnd -ge $Bytes.Length) {
    Write-Error "Could not find JSON '}', searched whole file"
    return 11
}

$JSONHeader = [System.Text.Encoding]::ASCII.GetString($Bytes, $JSONOffsetStart, $JSONOffsetEnd - $JSONOffsetStart + 1)
$Header = ConvertFrom-JSON $JSONHeader
Write-Output "Header found!"

$FrameRate = $Header.framerate * $FPSMultiplier

# Create mp4 file
$FFmpegExe = Join-Path $ScriptPath "ffmpeg.exe"
if (-not $(Test-Path -Path $FFMpegExe)) {
    Write-Error "Cannot find 'ffmpeg.exe'"
    return 2
}

$InputFiles = "$FullPrefix%05d.jpg"
$OutFileName = "$($BaseName)_x$($FPSMultiplier)_speed.mp4"

if (-not $Force -and $(Test-Path $OutFileName)) {
    Write-Error "$OutFileName already exists. Use -Force to overwrite."
    return 17
}

& $FFmpegExe -y -f image2 -r $FrameRate -i $InputFiles $OutFileName

if (-not $Cache -and $($LASTEXITCODE -eq 0)) {
    Remove-Item -Recurse -Force -Path $OutPath
}
