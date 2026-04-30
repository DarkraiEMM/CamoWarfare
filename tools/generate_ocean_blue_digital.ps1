$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$resourcesRoot = Join-Path $root "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"
$dataRoot = Join-Path $resourcesRoot "data"

$familyId = "ocean_blue_digital"
$textureDir = Join-Path $assetsRoot ("textures\block\" + $familyId)
$blockstateRoot = Join-Path $assetsRoot "blockstates"
$blockModelRoot = Join-Path $assetsRoot "models\block"
$itemModelRoot = Join-Path $assetsRoot "models\item"
$lootRoot = Join-Path $dataRoot "camowarfare\loot_tables\blocks"
$pickaxeTagPath = Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json"
$armoredTagPath = Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json"

$palette = @{
    Base = [System.Drawing.ColorTranslator]::FromHtml("#96A8C4")
    Light = [System.Drawing.ColorTranslator]::FromHtml("#D9E4F2")
    Mist = [System.Drawing.ColorTranslator]::FromHtml("#B9C9DF")
    Sky = [System.Drawing.ColorTranslator]::FromHtml("#6D90C8")
    Cobalt = [System.Drawing.ColorTranslator]::FromHtml("#2F62B8")
    Navy = [System.Drawing.ColorTranslator]::FromHtml("#243E68")
    Shadow = [System.Drawing.ColorTranslator]::FromHtml("#1B2C49")
}

$cell = 8

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Save-Json([string]$Path, $Data) {
    Ensure-Dir (Split-Path -Parent $Path)
    $json = $Data | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
}

function New-Bitmap([int]$Width, [int]$Height) {
    return [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function New-SeedRandom([string]$Seed) {
    return [System.Random]::new([Math]::Abs($Seed.GetHashCode()))
}

function Wrap-Coord([int]$Value, [int]$Size) {
    return (($Value % $Size) + $Size) % $Size
}

function Set-WrappedPixel([System.Drawing.Bitmap]$Bitmap, [int]$X, [int]$Y, [System.Drawing.Color]$Color) {
    $Bitmap.SetPixel((Wrap-Coord $X $Bitmap.Width), (Wrap-Coord $Y $Bitmap.Height), $Color)
}

function Fill-WrappedRect(
    [System.Drawing.Bitmap]$Bitmap,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [System.Drawing.Color]$Color
) {
    for ($dx = 0; $dx -lt $Width; $dx++) {
        for ($dy = 0; $dy -lt $Height; $dy++) {
            Set-WrappedPixel $Bitmap ($X + $dx) ($Y + $dy) $Color
        }
    }
}

function Add-SteppedRibbon(
    [System.Drawing.Bitmap]$Bitmap,
    [System.Random]$Random,
    [int]$StartY,
    [System.Drawing.Color]$Color,
    [int]$MinHeight,
    [int]$MaxHeight,
    [int]$DriftLimit
) {
    $cursorX = -($cell * 6)
    $y = $StartY

    while ($cursorX -lt ($Bitmap.Width + ($cell * 4))) {
        $stepWidth = $MinHeight + ($Random.Next(5) * $cell)
        $height = $MinHeight + ($Random.Next([Math]::Max(1, [int](($MaxHeight - $MinHeight) / $cell) + 1)) * $cell)
        Fill-WrappedRect $Bitmap $cursorX $y $stepWidth $height $Color

        if ($Random.NextDouble() -lt 0.65) {
            $nubWidth = $cell + ($Random.Next(3) * $cell)
            $nubHeight = $cell + ($Random.Next(2) * $cell)
            $nubX = $cursorX + ($Random.Next([Math]::Max(1, [int]($stepWidth / $cell))) * $cell)
            $nubY = $y - $cell + ($Random.Next([Math]::Max(1, [int](($height + $cell) / $cell))) * $cell)
            Fill-WrappedRect $Bitmap $nubX $nubY $nubWidth $nubHeight $Color
        }

        if ($Random.NextDouble() -lt 0.35) {
            $tailY = $y + ($Random.Next([Math]::Max(1, [int]($height / $cell))) * $cell)
            Fill-WrappedRect $Bitmap ($cursorX + $stepWidth - [int]($cell / 2)) $tailY ($cell + ($Random.Next(3) * $cell)) $cell $Color
        }

        if ($Random.NextDouble() -lt 0.72) {
            $y += ($Random.Next(3) - 1) * $cell
            $y = [Math]::Max(-$cell, [Math]::Min($Bitmap.Height - $cell, $y))
            $y = [Math]::Max($StartY - $DriftLimit, [Math]::Min($StartY + $DriftLimit, $y))
        }

        $cursorX += $stepWidth - [int]($cell / 2) + ($Random.Next(3) * $cell)
    }
}

function Add-DigitalCluster(
    [System.Drawing.Bitmap]$Bitmap,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$CenterX,
    [int]$CenterY,
    [int]$RadiusX,
    [int]$RadiusY,
    [int]$Count
) {
    for ($i = 0; $i -lt $Count; $i++) {
        $x = $CenterX + (($Random.Next(($RadiusX * 2) + 1) - $RadiusX) * $cell)
        $y = $CenterY + (($Random.Next(($RadiusY * 2) + 1) - $RadiusY) * $cell)
        $w = $cell + ($Random.Next(3) * $cell)
        $h = $cell + ($Random.Next(3) * $cell)
        Fill-WrappedRect $Bitmap $x $y $w $h $Color
    }
}

function Add-FieldNoise(
    [System.Drawing.Bitmap]$Bitmap,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$Count,
    [int]$MaxSize
) {
    for ($i = 0; $i -lt $Count; $i++) {
        $x = $Random.Next([int]($Bitmap.Width / $cell)) * $cell
        $y = $Random.Next([int]($Bitmap.Height / $cell)) * $cell
        $size = $cell + ($Random.Next($MaxSize) * $cell)
        Fill-WrappedRect $Bitmap $x $y $size $cell $Color
        if ($Random.NextDouble() -lt 0.4) {
            Fill-WrappedRect $Bitmap ($x + $cell) ($y + $cell) ([Math]::Max($cell, $size - $cell)) $cell $Color
        }
    }
}

function New-MasterPattern() {
    $bitmap = New-Bitmap 256 256
    $random = New-SeedRandom $familyId

    for ($x = 0; $x -lt $bitmap.Width; $x++) {
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            Set-WrappedPixel $bitmap $x $y $palette.Base
        }
    }

    $bands = @(16, 48, 80, 112, 144, 176, 208, 232)
    foreach ($bandY in $bands) {
        Add-SteppedRibbon $bitmap $random $bandY $palette.Mist 16 32 16
        if ($random.NextDouble() -lt 0.85) {
            Add-SteppedRibbon $bitmap $random ($bandY + $cell) $palette.Sky 16 24 24
        }
        if ($random.NextDouble() -lt 0.60) {
            Add-SteppedRibbon $bitmap $random ($bandY + $cell) $palette.Cobalt 8 24 24
        }
        if ($random.NextDouble() -lt 0.45) {
            Add-SteppedRibbon $bitmap $random ($bandY - $cell) $palette.Navy 8 16 16
        }
    }

    foreach ($cluster in @(
        @{ X = 32;  Y = 32;  Color = $palette.Light; Count = 8 },
        @{ X = 112; Y = 48;  Color = $palette.Light; Count = 10 },
        @{ X = 208; Y = 32;  Color = $palette.Light; Count = 7 },
        @{ X = 64;  Y = 120; Color = $palette.Cobalt; Count = 10 },
        @{ X = 168; Y = 104; Color = $palette.Navy; Count = 8 },
        @{ X = 216; Y = 152; Color = $palette.Cobalt; Count = 8 },
        @{ X = 48;  Y = 184; Color = $palette.Light; Count = 9 },
        @{ X = 144; Y = 208; Color = $palette.Shadow; Count = 6 },
        @{ X = 224; Y = 224; Color = $palette.Light; Count = 8 }
    )) {
        Add-DigitalCluster $bitmap $random $cluster.Color $cluster.X $cluster.Y 4 3 $cluster.Count
    }

    Add-FieldNoise $bitmap $random $palette.Light 22 3
    Add-FieldNoise $bitmap $random $palette.Mist 18 2
    Add-FieldNoise $bitmap $random $palette.Navy 14 2
    Add-FieldNoise $bitmap $random $palette.Cobalt 16 2

    return $bitmap
}

function Save-VariantTextures([System.Drawing.Bitmap]$Master, [string]$Variant, [int]$X, [int]$Y) {
    $tile = $Master.Clone([System.Drawing.Rectangle]::new($X, $Y, 128, 128), $Master.PixelFormat)
    try {
        Ensure-Dir $textureDir
        $tile.Save((Join-Path $textureDir ($Variant + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
        $tile.Save((Join-Path $textureDir ($Variant + "_atlas.png")), [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $tile.Dispose()
    }
}

function Write-BlockResources([string]$Variant) {
    $blockId = "${familyId}_${Variant}_block"
    $textureRef = "camowarfare:block/${familyId}/${Variant}_atlas"

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
            all = $textureRef
            particle = $textureRef
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

function Ensure-TagValue([string]$Path, [string]$Entry) {
    $json = Get-Content -Raw -Path $Path | ConvertFrom-Json
    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($value in $json.values) {
        $values.Add([string]$value)
    }
    if (-not $values.Contains($Entry)) {
        $values.Add($Entry)
    }
    $json.values = @($values)
    Save-Json $Path $json
}

$master = New-MasterPattern
try {
    Save-VariantTextures $master "a" 0 0
    Save-VariantTextures $master "b" 128 0
    Save-VariantTextures $master "c" 0 128
    Save-VariantTextures $master "d" 128 128
}
finally {
    $master.Dispose()
}

foreach ($variant in @("a", "b", "c", "d")) {
    Write-BlockResources $variant
    $entry = "camowarfare:${familyId}_${variant}_block"
    Ensure-TagValue $pickaxeTagPath $entry
    Ensure-TagValue $armoredTagPath $entry
}

Write-Output "Generated $familyId assets"
