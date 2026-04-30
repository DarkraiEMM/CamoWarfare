$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$resourcesRoot = Join-Path $root "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"
$dataRoot = Join-Path $resourcesRoot "data"

$familyId = "pla_mountain_tiger"
$textureDir = Join-Path $assetsRoot ("textures\block\" + $familyId)
$blockstateRoot = Join-Path $assetsRoot "blockstates"
$blockModelRoot = Join-Path $assetsRoot "models\block"
$itemModelRoot = Join-Path $assetsRoot "models\item"
$lootRoot = Join-Path $dataRoot "camowarfare\loot_tables\blocks"
$recipeOriginalRoot = Join-Path $dataRoot "camowarfare\recipe\original"
$recipeCreateMixingRoot = Join-Path $dataRoot "camowarfare\recipe\compat\create\mixing"
$recipeStonecuttingRoot = Join-Path $dataRoot "camowarfare\recipe\stonecutting"
$recipeCreateCuttingRoot = Join-Path $dataRoot "camowarfare\recipe\compat\create\cutting"
$pickaxeTagPath = Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json"
$armoredTagPath = Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json"

$palette = @{
    Base = [System.Drawing.ColorTranslator]::FromHtml("#2F2B33")
    Brown = [System.Drawing.ColorTranslator]::FromHtml("#4A3D38")
    Olive = [System.Drawing.ColorTranslator]::FromHtml("#67734F")
    OliveDark = [System.Drawing.ColorTranslator]::FromHtml("#4F5A3D")
    Khaki = [System.Drawing.ColorTranslator]::FromHtml("#D9D09D")
}

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
    $wrappedX = Wrap-Coord $X $Bitmap.Width
    $wrappedY = Wrap-Coord $Y $Bitmap.Height
    $Bitmap.SetPixel($wrappedX, $wrappedY, $Color)
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

function Draw-TigerStripe(
    [System.Drawing.Bitmap]$Bitmap,
    [System.Random]$Random,
    [double]$CenterX,
    [double]$Width,
    [double]$Phase,
    [double]$AmplitudeA,
    [double]$AmplitudeB,
    [double]$FreqA,
    [double]$FreqB
) {
    $edgeOnLeft = $Random.NextDouble() -gt 0.38
    $primary = if ($Random.NextDouble() -gt 0.45) { $palette.Olive } else { $palette.OliveDark }

    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        $curve =
            ([Math]::Sin(($y * $FreqA) + $Phase) * $AmplitudeA) +
            ([Math]::Sin(($y * $FreqB) + ($Phase * 0.57)) * $AmplitudeB)
        $pixelCenter = [int][Math]::Round($CenterX + $curve)
        $halfWidth = [int][Math]::Round($Width / 2.0)
        $left = $pixelCenter - $halfWidth
        $right = $pixelCenter + $halfWidth

        for ($x = $left; $x -le $right; $x++) {
            $useDark = ((($x + ($y * 2)) % 11) -eq 0) -or ((($x * 3 + $y) % 17) -eq 0)
            $color = if ($useDark) { $palette.OliveDark } else { $primary }
            Set-WrappedPixel $Bitmap $x $y $color
        }

        $edgeWidth = 2 + $Random.Next(3)
        if ($edgeOnLeft) {
            for ($edge = 1; $edge -le $edgeWidth; $edge++) {
                if ((($y + $edge) % 5) -ne 0) {
                    Set-WrappedPixel $Bitmap ($left - $edge) $y $palette.Khaki
                }
            }
        }
        else {
            for ($edge = 1; $edge -le $edgeWidth; $edge++) {
                if ((($y + $edge) % 5) -ne 0) {
                    Set-WrappedPixel $Bitmap ($right + $edge) $y $palette.Khaki
                }
            }
        }
    }
}

function Add-VerticalFragments([System.Drawing.Bitmap]$Bitmap, [System.Random]$Random) {
    for ($i = 0; $i -lt 34; $i++) {
        $x = $Random.Next($Bitmap.Width)
        $y = $Random.Next($Bitmap.Height)
        $height = 10 + $Random.Next(38)
        $width = 2 + $Random.Next(6)
        $color = if ($Random.NextDouble() -gt 0.55) { $palette.Brown } else { $palette.Base }
        for ($step = 0; $step -lt $height; $step++) {
            $shift = [int][Math]::Round([Math]::Sin(($step * 0.42) + ($i * 0.73)) * (1 + $Random.NextDouble() * 2.5))
            Fill-WrappedRect $Bitmap ($x + $shift) ($y + $step) $width 1 $color
        }
    }
}

function Add-DarkBreaks([System.Drawing.Bitmap]$Bitmap, [System.Random]$Random) {
    for ($i = 0; $i -lt 48; $i++) {
        $x = $Random.Next($Bitmap.Width)
        $y = $Random.Next($Bitmap.Height)
        $width = 3 + $Random.Next(7)
        $height = 2 + $Random.Next(9)
        $color = if ($Random.NextDouble() -gt 0.5) { $palette.Base } else { $palette.Brown }
        Fill-WrappedRect $Bitmap $x $y $width $height $color
    }
}

function New-MasterPattern() {
    $bitmap = New-Bitmap 256 256
    $random = New-SeedRandom $familyId
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear($palette.Base)
    }
    finally {
        $graphics.Dispose()
    }

    for ($stripe = 0; $stripe -lt 10; $stripe++) {
        $centerX = -12 + ($stripe * 28) + ($random.NextDouble() * 12)
        $width = 12 + ($random.NextDouble() * 14)
        $phase = $random.NextDouble() * [Math]::PI * 2.0
        $amplitudeA = 6 + ($random.NextDouble() * 8)
        $amplitudeB = 2 + ($random.NextDouble() * 5)
        $freqA = 0.038 + ($random.NextDouble() * 0.022)
        $freqB = 0.094 + ($random.NextDouble() * 0.038)
        Draw-TigerStripe $bitmap $random $centerX $width $phase $amplitudeA $amplitudeB $freqA $freqB
    }

    Add-VerticalFragments $bitmap $random
    Add-DarkBreaks $bitmap $random
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
}

Save-Json (Join-Path $recipeOriginalRoot ($familyId + "_a_block.json")) @{
    type = "minecraft:crafting_shaped"
    category = "building"
    pattern = @("XXX", "XYX", "XXX")
    key = @{
        X = @{ item = "camowarfare:solid_military_green_a_block" }
        Y = @{ item = "minecraft:black_dye" }
    }
    result = @{
        id = "camowarfare:${familyId}_a_block"
        count = 8
    }
}

Save-Json (Join-Path $recipeCreateMixingRoot ($familyId + "_a_block.json")) @{
    "neoforge:conditions" = @(
        @{
            type = "neoforge:mod_loaded"
            modid = "create"
        }
    )
    type = "create:mixing"
    ingredients = @(
        @{ item = "camowarfare:solid_military_green_a_block" },
        @{ item = "camowarfare:solid_military_green_a_block" },
        @{ item = "camowarfare:solid_military_green_a_block" },
        @{ item = "camowarfare:solid_military_green_a_block" },
        @{ item = "camowarfare:solid_military_green_a_block" },
        @{ item = "camowarfare:solid_military_green_a_block" },
        @{ item = "camowarfare:solid_military_green_a_block" },
        @{ item = "camowarfare:solid_military_green_a_block" },
        @{ item = "minecraft:black_dye" }
    )
    results = @(
        @{
            id = "camowarfare:${familyId}_a_block"
            count = 8
        }
    )
}

$variants = @("a", "b", "c", "d")
foreach ($to in $variants) {
    foreach ($from in $variants) {
        if ($to -eq $from) {
            continue
        }

        $recipeName = "${familyId}_${to}_from_${from}.json"
        $sourceBlock = "camowarfare:${familyId}_${from}_block"
        $targetBlock = "camowarfare:${familyId}_${to}_block"

        Save-Json (Join-Path $recipeStonecuttingRoot $recipeName) @{
            type = "minecraft:stonecutting"
            ingredient = @{
                item = $sourceBlock
            }
            result = @{
                id = $targetBlock
                count = 1
            }
        }

        Save-Json (Join-Path $recipeCreateCuttingRoot $recipeName) @{
            "neoforge:conditions" = @(
                @{
                    type = "neoforge:mod_loaded"
                    modid = "create"
                }
            )
            type = "create:cutting"
            ingredients = @(
                @{
                    item = $sourceBlock
                }
            )
            processing_time = 50
            results = @(
                @{
                    id = $targetBlock
                    count = 1
                }
            )
        }
    }
}

foreach ($variant in $variants) {
    $entry = "camowarfare:${familyId}_${variant}_block"
    Ensure-TagValue $pickaxeTagPath $entry
    Ensure-TagValue $armoredTagPath $entry
}

Write-Output "Generated $familyId assets"
