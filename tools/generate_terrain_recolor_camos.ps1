$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $root "src\main\resources\assets\camowarfare"
$dataRoot = Join-Path $root "src\main\resources\data"
$textureRoot = Join-Path $assetsRoot "textures\block"
$blockstateRoot = Join-Path $assetsRoot "blockstates"
$blockModelRoot = Join-Path $assetsRoot "models\block"
$itemModelRoot = Join-Path $assetsRoot "models\item"
$lootRoot = Join-Path $dataRoot "camowarfare\loot_tables\blocks"
$pickaxeTagPath = Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json"
$armoredTagPath = Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json"
$enLangPath = Join-Path $assetsRoot "lang\en_us.json"
$zhLangPath = Join-Path $assetsRoot "lang\zh_cn.json"

function Ensure-Dir([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Save-Json([string]$Path, $Data) {
    Ensure-Dir (Split-Path -Parent $Path)
    $json = $Data | ConvertTo-Json -Depth 24
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function ConvertTo-Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function Get-Luma([System.Drawing.Color]$Color) {
    return (0.2126 * $Color.R) + (0.7152 * $Color.G) + (0.0722 * $Color.B)
}

function Get-ResourcePath([string]$Resource) {
    return Join-Path $textureRoot ($Resource + ".png")
}

function Copy-ScaledBitmap([System.Drawing.Bitmap]$Source, [int]$Size) {
    $target = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($target)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    try {
        $graphics.DrawImage(
            $Source,
            [System.Drawing.Rectangle]::new(0, 0, $Size, $Size),
            [System.Drawing.Rectangle]::new(0, 0, $Source.Width, $Source.Height),
            [System.Drawing.GraphicsUnit]::Pixel
        )
    }
    finally {
        $graphics.Dispose()
    }
    return $target
}

function New-RecoloredBitmap([System.Drawing.Bitmap]$Source, [string[]]$PaletteHex) {
    $palette = @($PaletteHex | ForEach-Object { ConvertTo-Color $_ } | Sort-Object { Get-Luma $_ })
    $colors = @{}

    for ($y = 0; $y -lt $Source.Height; $y++) {
        for ($x = 0; $x -lt $Source.Width; $x++) {
            $color = $Source.GetPixel($x, $y)
            if ($color.A -gt 0) {
                $colors[$color.ToArgb()] = $color
            }
        }
    }

    $sourceColors = @($colors.Values | Sort-Object { Get-Luma $_ })
    $colorMap = @{}
    $sourceMax = [Math]::Max(1, $sourceColors.Count - 1)
    $paletteMax = [Math]::Max(1, $palette.Count - 1)

    for ($i = 0; $i -lt $sourceColors.Count; $i++) {
        $paletteIndex = [int][Math]::Round(($i / [double]$sourceMax) * $paletteMax)
        $sourceColor = $sourceColors[$i]
        $targetColor = $palette[$paletteIndex]
        $colorMap[$sourceColor.ToArgb()] = [System.Drawing.Color]::FromArgb($sourceColor.A, $targetColor.R, $targetColor.G, $targetColor.B)
    }

    $target = [System.Drawing.Bitmap]::new($Source.Width, $Source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $Source.Height; $y++) {
        for ($x = 0; $x -lt $Source.Width; $x++) {
            $color = $Source.GetPixel($x, $y)
            if ($color.A -eq 0) {
                $target.SetPixel($x, $y, $color)
            }
            else {
                $target.SetPixel($x, $y, $colorMap[$color.ToArgb()])
            }
        }
    }

    return $target
}

function Add-JsonValue([string]$Path, [string]$Value) {
    $json = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($existing in $json.values) {
        $values.Add([string]$existing)
    }
    if (-not $values.Contains($Value)) {
        $values.Add($Value)
    }
    Save-Json $Path ([ordered]@{
        replace = [bool]$json.replace
        values = @($values)
    })
}

function Add-LangEntry([string]$Path, [string]$Key, [string]$Value) {
    $json = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    $json | Add-Member -NotePropertyName $Key -NotePropertyValue $Value -Force
    Save-Json $Path $json
}

function Save-TerrainBlockResources($Entry, [string]$SizeId, [int]$TilePixels, [string]$SizeEn, [string]$SizeZh) {
    $blockId = "$($Entry.Id)_${SizeId}_block"
    $textureBase = "camowarfare:block/$($Entry.Id)"

    Save-Json (Join-Path $blockstateRoot ($blockId + ".json")) ([ordered]@{
        multipart = @(
            [ordered]@{
                apply = [ordered]@{
                    model = "camowarfare:block/${blockId}_0"
                }
            }
        )
    })

    Save-Json (Join-Path $blockModelRoot ($blockId + ".json")) ([ordered]@{
        parent = "camowarfare:block/${blockId}_0"
        render_type = "minecraft:solid"
        textures = [ordered]@{
            particle = "$textureBase/variant_1"
        }
    })

    Save-Json (Join-Path $blockModelRoot ($blockId + "_0.json")) ([ordered]@{
        parent = "minecraft:block/block"
        render_type = "minecraft:cutout"
        loader = "camowarfare:connected_camo"
        position_tiled = $true
        position_tile_pixels = $TilePixels
        textures = [ordered]@{
            atlas = "$textureBase/variant_0"
            particle = "$textureBase/variant_1"
            copycat_atlas = "$textureBase/variant_1"
            edge = "camowarfare:block/definition_sample/edge"
            rivet = "camowarfare:block/definition_sample/rivet"
        }
    })

    Save-Json (Join-Path $itemModelRoot ($blockId + ".json")) ([ordered]@{
        parent = "minecraft:block/cube_all"
        textures = [ordered]@{
            all = "$textureBase/variant_1"
        }
    })

    Save-Json (Join-Path $lootRoot ($blockId + ".json")) ([ordered]@{
        type = "minecraft:block"
        pools = @(
            [ordered]@{
                rolls = 1.0
                bonus_rolls = 0.0
                entries = @(
                    [ordered]@{
                        type = "minecraft:item"
                        name = "camowarfare:$blockId"
                    }
                )
                conditions = @(
                    [ordered]@{
                        condition = "minecraft:survives_explosion"
                    }
                )
            }
        )
    })

    Add-JsonValue $pickaxeTagPath "camowarfare:$blockId"
    Add-JsonValue $armoredTagPath "camowarfare:$blockId"
    Add-LangEntry $enLangPath "block.camowarfare.$blockId" "$($Entry.BaseEn) $($Entry.TerrainEn) Coating Block ($SizeEn)"
}

$terrainPalettes = @{
    woodland = @("#121A12", "#26351F", "#435633", "#687548", "#8A704C")
    mountain = @("#2C3428", "#46513D", "#69735A", "#8A8067", "#A79B7F")
    desert = @("#5A432F", "#7A5B3B", "#A9865A", "#C8B083", "#E0CFAB")
    snow = @("#4A5257", "#6F7A80", "#A9B3B8", "#D8DEE0", "#F1F3F2")
    urban = @("#2E353A", "#4C555B", "#6D777D", "#8E979B", "#BCC2C3")
}

$bases = @(
    @{ Prefix = "pla"; BaseEn = "PLA Camo"; Source = "definition_sample/variant_0" },
    @{ Prefix = "nato"; BaseEn = "NATO Camo"; Source = "nato_tricolor_mountain/variant_0" },
    @{ Prefix = "turkish"; BaseEn = "Turkish Camo"; Source = "turkish_multiterrain/variant_0" },
    @{ Prefix = "edrl"; BaseEn = "EDRL Camo"; Source = "edrl_green/variant_0" },
    @{ Prefix = "emr"; BaseEn = "EMR Camo"; Source = "russian_emr/variant_0" },
    @{ Prefix = "ocp"; BaseEn = "OCP Camo"; Source = "us_ocp_multicam/variant_0" }
)

$terrains = @(
    @{ Id = "woodland"; TerrainEn = "Woodland" },
    @{ Id = "mountain"; TerrainEn = "Mountain" },
    @{ Id = "desert"; TerrainEn = "Desert" },
    @{ Id = "snow"; TerrainEn = "Snow" },
    @{ Id = "urban"; TerrainEn = "Urban" }
)

foreach ($base in $bases) {
    $sourcePath = Get-ResourcePath $base.Source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing source texture: $sourcePath"
    }

    $source = [System.Drawing.Bitmap]::new($sourcePath)
    try {
        foreach ($terrain in $terrains) {
            $terrainId = $terrain["Id"]
            $entry = [ordered]@{
                Id = "$($base.Prefix)_$terrainId"
                BaseEn = $base.BaseEn
                TerrainEn = $terrain.TerrainEn
            }

            $targetDir = Join-Path $textureRoot $entry.Id
            Ensure-Dir $targetDir

            $palette = $terrainPalettes[$terrainId]
            $recolored = New-RecoloredBitmap $source $palette
            try {
                $variant1 = Copy-ScaledBitmap $recolored 256
                try {
                    $recolored.Save((Join-Path $targetDir "variant_0.png"), [System.Drawing.Imaging.ImageFormat]::Png)
                    $variant1.Save((Join-Path $targetDir "variant_1.png"), [System.Drawing.Imaging.ImageFormat]::Png)
                }
                finally {
                    $variant1.Dispose()
                }
            }
            finally {
                $recolored.Dispose()
            }

            Save-TerrainBlockResources $entry "standard" 64 "Standard" "常规"
            Save-TerrainBlockResources $entry "large" 32 "Large" "大型"
        }
    }
    finally {
        $source.Dispose()
    }
}

Write-Output "Generated terrain recolor camo blocks: 60"
