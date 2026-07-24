param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$compat = Join-Path $Root "BiaoGe\Core\Compat.lua"
$text = Get-Content -LiteralPath $compat -Raw
$failures = @()

if ($text -match "C_Item\.GetItemInfo\s*=\s*ns\.GetItemInfo") {
    $failures += "Compat.lua must not replace shared C_Item.GetItemInfo."
}

if ($text -match "C_Item\.GetItemInfoInstant\s*=\s*ns\.GetItemInfoInstant") {
    $failures += "Compat.lua must not replace shared C_Item.GetItemInfoInstant."
}

if ($text -notmatch "local _GetItemInfo = \(C_Item and C_Item\.GetItemInfo\) or GetItemInfo") {
    $failures += "BiaoGe item wrapper must prefer the ClassicAPI C_Item.GetItemInfo provider."
}

if ($text -notmatch "local _GetItemInfoInstant = \(C_Item and C_Item\.GetItemInfoInstant\) or GetItemInfoInstant") {
    $failures += "BiaoGe instant wrapper must prefer the ClassicAPI C_Item.GetItemInfoInstant provider."
}

if ($text -notmatch "local _GetItemSubClassInfo = \(C_Item and C_Item\.GetItemSubClassInfo\) or GetItemSubClassInfo") {
    $failures += "Legacy subclass fallback must prefer the nil-safe ClassicAPI provider."
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error $failure -ErrorAction Continue
    }
    exit 1
}

Write-Output "PASS BiaoGe keeps ClassicAPI C_Item providers isolated"
