$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$javaPath = Join-Path $root "src\main\java\com\camowarfare\CamoFamily.java"
$dataRoot = Join-Path $root "src\main\resources\data"

function Read-JsonValues([string]$Path) {
    return @((Get-Content -Raw -Path $Path | ConvertFrom-Json).values)
}

$source = Get-Content -Raw -Path $javaPath
$matches = [regex]::Matches(
    $source,
    '^\s*[A-Z0-9_]+\("([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*MapColor\.[A-Z_]+,\s*(null|"([^"]+)")\)',
    [System.Text.RegularExpressions.RegexOptions]::Multiline
)

$registered = New-Object System.Collections.Generic.HashSet[string]
@(
    "camowarfare:armor_plate_block",
    "camowarfare:add_on_armor_plate_block",
    "camowarfare:slat_armor_block"
) | ForEach-Object { $registered.Add($_) | Out-Null }

foreach ($color in @("military_green", "desert_sand", "bluegray", "night_black")) {
    $registered.Add("camowarfare:add_on_armor_plate_${color}_block") | Out-Null
    $registered.Add("camowarfare:slat_armor_${color}_block") | Out-Null
}

foreach ($match in $matches) {
    $familyId = $match.Groups[1].Value
    foreach ($variant in @("a", "b", "c", "d")) {
        $registered.Add("camowarfare:${familyId}_${variant}_block") | Out-Null
    }
    if ($match.Groups[5].Success -and $match.Groups[5].Value) {
        $registered.Add("camowarfare:" + $match.Groups[5].Value) | Out-Null
    }
}

$pickaxeValues = Read-JsonValues (Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json")
$attachmentValues = Read-JsonValues (Join-Path $dataRoot "camowarfare\tags\block\attachment_blocks.json")
$addOnValues = Read-JsonValues (Join-Path $dataRoot "camowarfare\tags\block\add_on_armor_blocks.json")
$slatValues = Read-JsonValues (Join-Path $dataRoot "camowarfare\tags\block\slat_armor_blocks.json")
$armoredValues = Read-JsonValues (Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json")
$simulatedValues = Read-JsonValues (Join-Path $dataRoot "camowarfare\tags\block\simulated_physics_blocks.json")

$resolvedPickaxe = New-Object System.Collections.Generic.HashSet[string]
foreach ($id in $pickaxeValues) {
    if ($id -eq "#camowarfare:attachment_blocks") {
        foreach ($entry in $attachmentValues) { $resolvedPickaxe.Add($entry) | Out-Null }
    } else {
        $resolvedPickaxe.Add($id) | Out-Null
    }
}

$resolvedArmored = New-Object System.Collections.Generic.HashSet[string]
foreach ($id in $armoredValues) {
    if ($id -eq "#camowarfare:add_on_armor_blocks") {
        foreach ($entry in $addOnValues) { $resolvedArmored.Add($entry) | Out-Null }
    } elseif ($id -eq "#camowarfare:slat_armor_blocks") {
        foreach ($entry in $slatValues) { $resolvedArmored.Add($entry) | Out-Null }
    } else {
        $resolvedArmored.Add($id) | Out-Null
    }
}

$resolvedSimulated = New-Object System.Collections.Generic.HashSet[string]
foreach ($id in $simulatedValues) {
    if ($id -eq "#camowarfare:armored_camouflage_blocks") {
        foreach ($entry in $resolvedArmored) { $resolvedSimulated.Add($entry) | Out-Null }
    } elseif ($id -eq "#camowarfare:add_on_armor_blocks") {
        foreach ($entry in $addOnValues) { $resolvedSimulated.Add($entry) | Out-Null }
    } else {
        $resolvedSimulated.Add($id) | Out-Null
    }
}

$missingPickaxe = @($registered | Where-Object { -not $resolvedPickaxe.Contains($_) } | Sort-Object)
$missingArmored = @($registered | Where-Object { -not $resolvedArmored.Contains($_) } | Sort-Object)
$missingSimulated = @($registered | Where-Object { -not $resolvedSimulated.Contains($_) } | Sort-Object)

Write-Output ("Registered blocks: {0}" -f $registered.Count)
Write-Output ("Mineable/pickaxe missing: {0}" -f $missingPickaxe.Count)
if ($missingPickaxe.Count) { $missingPickaxe | ForEach-Object { Write-Output "  $_" } }
Write-Output ("Armored camouflage missing: {0}" -f $missingArmored.Count)
if ($missingArmored.Count) { $missingArmored | ForEach-Object { Write-Output "  $_" } }
Write-Output ("Simulated physics missing: {0}" -f $missingSimulated.Count)
if ($missingSimulated.Count) { $missingSimulated | ForEach-Object { Write-Output "  $_" } }

if ($missingPickaxe.Count -or $missingArmored.Count -or $missingSimulated.Count) {
    throw "CBC compatibility audit failed."
}

Write-Output "CBC compatibility audit passed."
