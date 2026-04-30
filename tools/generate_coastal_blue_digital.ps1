$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$resourcesRoot = Join-Path $root "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"
$dataRoot = Join-Path $resourcesRoot "data"

$familyId = "coastal_blue_digital"
$textureDir = Join-Path $assetsRoot ("textures\block\" + $familyId)
$blockstateRoot = Join-Path $assetsRoot "blockstates"
$blockModelRoot = Join-Path $assetsRoot "models\block"
$itemModelRoot = Join-Path $assetsRoot "models\item"
$lootRoot = Join-Path $dataRoot "camowarfare\loot_tables\blocks"
$pickaxeTagPath = Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json"
$armoredTagPath = Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json"

$palette = @{
    Base = [System.Drawing.ColorTranslator]::FromHtml("#F2F5F7")
    LightBlue = [System.Drawing.ColorTranslator]::FromHtml("#BFD1E8")
    MidBlue = [System.Drawing.ColorTranslator]::FromHtml("#6D94C8")
    StrongBlue = [System.Drawing.ColorTranslator]::FromHtml("#3F6FAF")
    Sand = [System.Drawing.ColorTranslator]::FromHtml("#D3C5AF")
    Dark = [System.Drawing.ColorTranslator]::FromHtml("#3A434D")
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

function Add-Patch(
    [System.Drawing.Bitmap]$Bitmap,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$StartX,
    [int]$StartY,
    [int]$Steps,
    [int]$MinWidth,
    [int]$MaxWidth,
    [int]$MinHeight,
    [int]$MaxHeight
) {
    $x = $StartX
    $y = $StartY

    for ($step = 0; $step -lt $Steps; $step++) {
        $width = $MinWidth + ($Random.Next([Math]::Max(1, [int](($MaxWidth - $MinWidth) / $cell) + 1)) * $cell)
        $height = $MinHeight + ($Random.Next([Math]::Max(1, [int](($MaxHeight - $MinHeight) / $cell) + 1)) * $cell)
        Fill-WrappedRect $Bitmap $x $y $width $height $Color

        if ($Random.NextDouble() -lt 0.65) {
            $branchX = $x + (($Random.Next([Math]::Max(1, [int]($width / $cell))) - 1) * $cell)
            $branchY = $y + (($Random.Next([Math]::Max(1, [int](($height + $cell) / $cell))) - 1) * $cell)
            $branchW = $cell + ($Random.Next(4) * $cell)
            $branchH = $cell + ($Random.Next(3) * $cell)
            Fill-WrappedRect $Bitmap $branchX $branchY $branchW $branchH $Color
        }

        if ($Random.NextDouble() -lt 0.45) {
            $stubX = $x - $cell + ($Random.Next([Math]::Max(1, [int](($width + ($cell * 2)) / $cell))) * $cell)
            $stubY = $y - $cell + ($Random.Next([Math]::Max(1, [int](($height + ($cell * 2)) / $cell))) * $cell)
            Fill-WrappedRect $Bitmap $stubX $stubY $cell ($cell + ($Random.Next(2) * $cell)) $Color
        }

        $x += (($Random.Next(5) - 2) * $cell)
        $y += (($Random.Next(5) - 2) * $cell)
    }
}

function Add-DigitalScatter(
    [System.Drawing.Bitmap]$Bitmap,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$Count
) {
    for ($i = 0; $i -lt $Count; $i++) {
        $x = $Random.Next([int]($Bitmap.Width / $cell)) * $cell
        $y = $Random.Next([int]($Bitmap.Height / $cell)) * $cell
        $w = $cell + ($Random.Next(3) * $cell)
        $h = $cell + ($Random.Next(3) * $cell)
        Fill-WrappedRect $Bitmap $x $y $w $h $Color

        if ($Random.NextDouble() -lt 0.35) {
            Fill-WrappedRect $Bitmap ($x + $cell) $y $cell $cell $Color
        }
    }
}

function Add-SeededPatchField(
    [System.Drawing.Bitmap]$Bitmap,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$Count,
    [int]$MinSteps,
    [int]$MaxSteps,
    [int]$MinWidth,
    [int]$MaxWidth,
    [int]$MinHeight,
    [int]$MaxHeight
) {
    for ($i = 0; $i -lt $Count; $i++) {
        $x = $Random.Next([int]($Bitmap.Width / $cell)) * $cell
        $y = $Random.Next([int]($Bitmap.Height / $cell)) * $cell
        $steps = $MinSteps + $Random.Next([Math]::Max(1, $MaxSteps - $MinSteps + 1))
        Add-Patch $Bitmap $Random $Color $x $y $steps $MinWidth $MaxWidth $MinHeight $MaxHeight
    }
}

function Clamp-Byte([int]$Value) {
    return [byte][Math]::Max(0, [Math]::Min(255, $Value))
}

function Apply-MatteFinish(
    [System.Drawing.Bitmap]$Bitmap,
    [System.Random]$Random
) {
    $gridWidth = [int]($Bitmap.Width / 16) + 2
    $gridHeight = [int]($Bitmap.Height / 16) + 2
    $shadeGrid = @()

    for ($gy = 0; $gy -lt $gridHeight; $gy++) {
        $row = @()
        for ($gx = 0; $gx -lt $gridWidth; $gx++) {
            $row += (-12 + $Random.Next(25))
        }
        $shadeGrid += ,$row
    }

    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
        for ($y = 0; $y -lt $Bitmap.Height; $y++) {
            $gx = [int]($x / 16)
            $gy = [int]($y / 16)
            $fx = ($x % 16) / 16.0
            $fy = ($y % 16) / 16.0

            $s00 = $shadeGrid[$gy][$gx]
            $s10 = $shadeGrid[$gy][$gx + 1]
            $s01 = $shadeGrid[$gy + 1][$gx]
            $s11 = $shadeGrid[$gy + 1][$gx + 1]

            $top = ($s00 * (1.0 - $fx)) + ($s10 * $fx)
            $bottom = ($s01 * (1.0 - $fx)) + ($s11 * $fx)
            $shade = [int][Math]::Round(($top * (1.0 - $fy)) + ($bottom * $fy))

            $hash = ($x * 37 + $y * 19 + ($gx * 13) + ($gy * 7)) % 11
            $grain = switch ($hash) {
                0 { -2 }
                1 { -1 }
                2 { 1 }
                3 { 2 }
                default { 0 }
            }

            $matte = -3
            $color = $Bitmap.GetPixel($x, $y)
            $brightness = [int](($color.R + $color.G + $color.B) / 3)
            $delta = $shade + $grain + $matte

            if ($brightness -gt 220 -and $delta -gt 4) {
                $delta = 4
            }
            if ($brightness -gt 235) {
                $delta -= 2
            }
            if ($brightness -lt 55 -and $delta -lt -5) {
                $delta = -5
            }

            $r = Clamp-Byte ([int]$color.R + $delta)
            $g = Clamp-Byte ([int]$color.G + $delta)
            $b = Clamp-Byte ([int]$color.B + $delta)
            $Bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($color.A, $r, $g, $b))
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

    Add-SeededPatchField $bitmap $random $palette.LightBlue 22 4 8 16 40 16 32
    Add-SeededPatchField $bitmap $random $palette.MidBlue 18 5 9 16 40 16 32
    Add-SeededPatchField $bitmap $random $palette.StrongBlue 12 4 8 16 32 16 24
    Add-SeededPatchField $bitmap $random $palette.Sand 8 3 6 16 32 16 24
    Add-SeededPatchField $bitmap $random $palette.Dark 9 3 6 16 24 16 24

    Add-DigitalScatter $bitmap $random $palette.LightBlue 34
    Add-DigitalScatter $bitmap $random $palette.MidBlue 28
    Add-DigitalScatter $bitmap $random $palette.StrongBlue 20
    Add-DigitalScatter $bitmap $random $palette.Sand 10
    Add-DigitalScatter $bitmap $random $palette.Dark 12
    Apply-MatteFinish $bitmap $random

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
