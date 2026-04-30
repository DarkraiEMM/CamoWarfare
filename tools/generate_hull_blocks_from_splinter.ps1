$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $root "src\main\resources\assets\camowarfare"
$dataRoot = Join-Path $root "src\main\resources\data"
$blockTextureRoot = Join-Path $assetsRoot "textures\block"
$blockstateRoot = Join-Path $assetsRoot "blockstates"
$blockModelRoot = Join-Path $assetsRoot "models\block"
$itemModelRoot = Join-Path $assetsRoot "models\item"
$lootRoot = Join-Path $dataRoot "camowarfare\loot_tables\blocks"
$pickaxeTagPath = Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json"
$armoredTagPath = Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json"

function Ensure-Dir([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Save-Png([System.Drawing.Bitmap]$Bitmap, [string]$Path) {
    Ensure-Dir (Split-Path -Parent $Path)
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Save-Json([string]$Path, $Data) {
    Ensure-Dir (Split-Path -Parent $Path)
    $json = $Data | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
}

function ConvertTo-Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function Get-Luminance([System.Drawing.Color]$Color) {
    return (0.2126 * $Color.R) + (0.7152 * $Color.G) + (0.0722 * $Color.B)
}

function Get-SortedSourceColors([System.Drawing.Bitmap]$Bitmap) {
    $counts = @{}
    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            $color = $Bitmap.GetPixel($x, $y)
            if ($color.A -eq 0) { continue }
            $key = "{0},{1},{2},{3}" -f $color.A, $color.R, $color.G, $color.B
            if (-not $counts.ContainsKey($key)) {
                $counts[$key] = @{
                    Color = $color
                    Count = 0
                }
            }
            $counts[$key].Count++
        }
    }

    return @(
        $counts.Values |
            Sort-Object -Property @{ Expression = "Count"; Descending = $true } |
            Select-Object -First 4 |
            Sort-Object -Property @{ Expression = { Get-Luminance $_.Color } }
    )
}

function Remap-Texture(
    [string]$SourcePath,
    [string]$TargetPath,
    [string[]]$TargetPaletteHex
) {
    $source = [System.Drawing.Bitmap]::FromFile($SourcePath)
    try {
        $target = New-Object System.Drawing.Bitmap $source.Width, $source.Height
        try {
            $sourceEntries = Get-SortedSourceColors $source
            $sourceColors = @($sourceEntries | ForEach-Object { $_.Color })
            $targetColors = @($TargetPaletteHex | ForEach-Object { ConvertTo-Color $_ } | Sort-Object -Property @{ Expression = { Get-Luminance $_ } })

            $mapping = @{}
            for ($i = 0; $i -lt [Math]::Min($sourceColors.Count, $targetColors.Count); $i++) {
                $src = $sourceColors[$i]
                $mapping["{0},{1},{2},{3}" -f $src.A, $src.R, $src.G, $src.B] = $targetColors[$i]
            }

            for ($y = 0; $y -lt $source.Height; $y++) {
                for ($x = 0; $x -lt $source.Width; $x++) {
                    $pixel = $source.GetPixel($x, $y)
                    if ($pixel.A -eq 0) {
                        $target.SetPixel($x, $y, $pixel)
                        continue
                    }

                    $key = "{0},{1},{2},{3}" -f $pixel.A, $pixel.R, $pixel.G, $pixel.B
                    if ($mapping.ContainsKey($key)) {
                        $mapped = $mapping[$key]
                        $target.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, $mapped.R, $mapped.G, $mapped.B))
                    }
                    else {
                        $target.SetPixel($x, $y, $pixel)
                    }
                }
            }

            Save-Png $target $TargetPath
        }
        finally {
            $target.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }
}

function Remap-HullTexture(
    [string]$SourcePath,
    [string]$TargetPath,
    [string[]]$TargetPaletteHex
) {
    $source = [System.Drawing.Bitmap]::FromFile($SourcePath)
    try {
        $target = New-Object System.Drawing.Bitmap $source.Width, $source.Height
        try {
            $sourceEntries = Get-SortedSourceColors $source
            $sourceColors = @($sourceEntries | ForEach-Object { $_.Color })
            $targetColors = @($TargetPaletteHex | ForEach-Object { ConvertTo-Color $_ } | Sort-Object -Property @{ Expression = { Get-Luminance $_ } })

            $baseColor = $targetColors[1]
            $accentDark = $targetColors[0]
            $accentMid = $targetColors[[Math]::Min(2, $targetColors.Count - 1)]
            $accentLight = $targetColors[[Math]::Min(3, $targetColors.Count - 1)]

            $mapping = @{}
            for ($i = 0; $i -lt [Math]::Min($sourceColors.Count, $targetColors.Count); $i++) {
                $src = $sourceColors[$i]
                $mapping["{0},{1},{2},{3}" -f $src.A, $src.R, $src.G, $src.B] = $targetColors[$i]
            }

            $seed = [Math]::Abs($TargetPath.GetHashCode())

            for ($y = 0; $y -lt $source.Height; $y++) {
                for ($x = 0; $x -lt $source.Width; $x++) {
                    $pixel = $source.GetPixel($x, $y)
                    if ($pixel.A -eq 0) {
                        $target.SetPixel($x, $y, $pixel)
                        continue
                    }

                    $key = "{0},{1},{2},{3}" -f $pixel.A, $pixel.R, $pixel.G, $pixel.B
                    $mapped = if ($mapping.ContainsKey($key)) { $mapping[$key] } else { $baseColor }

                    $final = $baseColor
                    $cellX = [int]($x / 18)
                    $cellY = [int]($y / 18)
                    $cellHash = [Math]::Abs((($cellX * 73856093) -bxor ($cellY * 19349663) -bxor $seed) % 41)
                    $localX = $x % 18
                    $localY = $y % 18

                    if ($cellHash -eq 0 -and $localX -in 6,7 -and $localY -in 5,6) {
                        $final = $accentDark
                    }
                    elseif ($cellHash -eq 1 -and $localX -in 10,11 -and $localY -in 8,9) {
                        $final = $accentMid
                    }
                    elseif ($cellHash -eq 2 -and $localX -in 3,4 -and $localY -in 12,13) {
                        $final = $accentLight
                    }
                    elseif ($cellHash -eq 3 -and $localX -eq 13 -and $localY -eq 4) {
                        $final = $mapped
                    }

                    $target.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, $final.R, $final.G, $final.B))
                }
            }

            Save-Png $target $TargetPath
        }
        finally {
            $target.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }
}

$families = @(
    @{
        Source = "pla_05_naval_blue"
        Target = "pla_05_naval_blue_hull"
        Palette = @("#23384B", "#35536A", "#172634", "#4A667E")
        HullMode = $true
    },
    @{
        Source = "winter_whitewash"
        Target = "winter_whitewash_hull"
        Palette = @("#D7DDD8", "#F4F7F5", "#AEB8B4", "#8F9A97")
        HullMode = $true
    },
    @{
        Source = "black_night"
        Target = "black_night_hull"
        Palette = @("#202429", "#3A4148", "#13171B", "#59626C")
        HullMode = $true
    },
    @{
        Source = "urban_digital"
        Target = "urban_digital_hull"
        Palette = @("#747A81", "#989FA7", "#565D65", "#3E454D")
        HullMode = $true
    }
)

foreach ($family in $families) {
    $targetDir = Join-Path $blockTextureRoot $family.Target
    Ensure-Dir $targetDir

    foreach ($variant in @("a", "b", "c", "d")) {
        $sourceTexture = Join-Path (Join-Path $blockTextureRoot $family.Source) ($variant + ".png")
        $sourceSample = Join-Path (Join-Path $blockTextureRoot $family.Source) ($variant + "_atlas.png")
        $targetTexture = Join-Path $targetDir ($variant + ".png")
        $targetSample = Join-Path $targetDir ($variant + "_atlas.png")

        if ($family.HullMode) {
            Remap-HullTexture -SourcePath $sourceTexture -TargetPath $targetTexture -TargetPaletteHex $family.Palette
            Remap-HullTexture -SourcePath $sourceSample -TargetPath $targetSample -TargetPaletteHex $family.Palette
        }
        else {
            Remap-Texture -SourcePath $sourceTexture -TargetPath $targetTexture -TargetPaletteHex $family.Palette
            Remap-Texture -SourcePath $sourceSample -TargetPath $targetSample -TargetPaletteHex $family.Palette
        }

        $blockId = "$($family.Target)_${variant}_block"
        Save-Json (Join-Path $blockstateRoot ($blockId + ".json")) @{
            multipart = @(
                @{
                    apply = @{
                        model = "camowarfare:block/$blockId"
                    }
                }
            )
        }

        Save-Json (Join-Path $blockModelRoot ($blockId + ".json")) @{
            parent = "minecraft:block/cube_all"
            render_type = "minecraft:solid"
            textures = @{
                all = "camowarfare:block/$($family.Target)/${variant}_atlas"
                particle = "camowarfare:block/$($family.Target)/${variant}_atlas"
            }
        }

        Save-Json (Join-Path $itemModelRoot ($blockId + ".json")) @{
            parent = "camowarfare:block/$blockId"
        }

        Save-Json (Join-Path $lootRoot ($blockId + ".json")) @{
            type = "minecraft:block"
            pools = @(
                @{
                    rolls = 1
                    entries = @(
                        @{
                            type = "minecraft:item"
                            name = "camowarfare:$blockId"
                        }
                    )
                    conditions = @(
                        @{
                            condition = "minecraft:survives_explosion"
                        }
                    )
                }
            )
        }
    }
}

$pickaxeJson = Get-Content -Raw -Path $pickaxeTagPath | ConvertFrom-Json
$pickaxeValues = [System.Collections.Generic.HashSet[string]]::new()
foreach ($value in $pickaxeJson.values) {
    $pickaxeValues.Add([string]$value) | Out-Null
}

$armoredJson = Get-Content -Raw -Path $armoredTagPath | ConvertFrom-Json
$armoredValues = [System.Collections.Generic.HashSet[string]]::new()
foreach ($value in $armoredJson.values) {
    $armoredValues.Add([string]$value) | Out-Null
}

foreach ($family in $families) {
    foreach ($variant in @("a", "b", "c", "d")) {
        $entry = "camowarfare:$($family.Target)_${variant}_block"
        $pickaxeValues.Add($entry) | Out-Null
        $armoredValues.Add($entry) | Out-Null
    }
}

$pickaxeJson.values = @($pickaxeValues | Sort-Object)
Save-Json $pickaxeTagPath $pickaxeJson

$armoredJson.values = @($armoredValues | Sort-Object)
Save-Json $armoredTagPath $armoredJson

Write-Output "hull blocks generated from splinter sources"
