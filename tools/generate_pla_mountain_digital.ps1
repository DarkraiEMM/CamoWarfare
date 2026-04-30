$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$resourcesRoot = Join-Path $root "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"
$dataRoot = Join-Path $resourcesRoot "data"

$familyId = "pla_mountain_digital"
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
    Base = [System.Drawing.ColorTranslator]::FromHtml("#6E705A")
    Light = [System.Drawing.ColorTranslator]::FromHtml("#A49A74")
    Olive = [System.Drawing.ColorTranslator]::FromHtml("#485640")
    Brown = [System.Drawing.ColorTranslator]::FromHtml("#70533B")
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

function Use-Graphics([System.Drawing.Bitmap]$Bitmap, [scriptblock]$Script) {
    $graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    try {
        & $Script $graphics
    }
    finally {
        $graphics.Dispose()
    }
}

function New-SeedRandom([string]$Seed) {
    return [System.Random]::new([Math]::Abs($Seed.GetHashCode()))
}

function Fill-WrappedRect(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Color]$Color,
    [float]$X,
    [float]$Y,
    [float]$Width,
    [float]$Height,
    [int]$TileSize
) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        foreach ($offsetX in @(-$TileSize, 0, $TileSize)) {
            foreach ($offsetY in @(-$TileSize, 0, $TileSize)) {
                $Graphics.FillRectangle($brush, $X + $offsetX, $Y + $offsetY, $Width, $Height)
            }
        }
    }
    finally {
        $brush.Dispose()
    }
}

function Add-DigitalClusters(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$TileSize,
    [int]$CellSize,
    [int]$ClusterCount,
    [int]$MinSteps,
    [int]$MaxSteps
) {
    $gridSize = [int]($TileSize / $CellSize)
    for ($cluster = 0; $cluster -lt $ClusterCount; $cluster++) {
        $steps = $MinSteps + $Random.Next([Math]::Max(1, $MaxSteps - $MinSteps + 1))
        $x = $Random.Next($gridSize)
        $y = $Random.Next($gridSize)

        for ($step = 0; $step -lt $steps; $step++) {
            $widthCells = 1 + $Random.Next(3)
            $heightCells = 1 + $Random.Next(2)
            Fill-WrappedRect $Graphics $Color ($x * $CellSize) ($y * $CellSize) ($widthCells * $CellSize) ($heightCells * $CellSize) $TileSize

            switch ($Random.Next(4)) {
                0 { $x = ($x + 1) % $gridSize }
                1 { $x = ($x - 1 + $gridSize) % $gridSize }
                2 { $y = ($y + 1) % $gridSize }
                default { $y = ($y - 1 + $gridSize) % $gridSize }
            }

            if ($Random.NextDouble() -gt 0.65) {
                $x = ($x + $Random.Next(-1, 2) + $gridSize) % $gridSize
                $y = ($y + $Random.Next(-1, 2) + $gridSize) % $gridSize
            }
        }
    }
}

function Add-BreakerRects(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$TileSize,
    [int]$CellSize,
    [int]$Count
) {
    for ($i = 0; $i -lt $Count; $i++) {
        $x = $Random.Next([int]($TileSize / $CellSize)) * $CellSize
        $y = $Random.Next([int]($TileSize / $CellSize)) * $CellSize
        $w = (2 + $Random.Next(3)) * $CellSize
        $h = (1 + $Random.Next(2)) * $CellSize
        Fill-WrappedRect $Graphics $Color $x $y $w $h $TileSize
    }
}

function Add-MacroPatch(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Color]$Color,
    [int]$TileSize,
    [int]$CellSize,
    [int[][]]$Cells
) {
    foreach ($cellRect in $Cells) {
        Fill-WrappedRect $Graphics $Color ($cellRect[0] * $CellSize) ($cellRect[1] * $CellSize) ($cellRect[2] * $CellSize) ($cellRect[3] * $CellSize) $TileSize
    }
}

function New-MasterPattern() {
    $bitmap = New-Bitmap 256 256

    Use-Graphics $bitmap {
        param($graphics)
        $graphics.Clear($palette.Base)

        Add-MacroPatch $graphics $palette.Olive 256 8 @(
            @(0, 4, 5, 5), @(4, 7, 3, 3), @(0, 9, 3, 3),
            @(8, 0, 5, 4), @(12, 3, 3, 3), @(9, 4, 2, 2),
            @(17, 3, 5, 5), @(15, 8, 3, 3), @(21, 7, 3, 3),
            @(25, 1, 5, 5), @(23, 6, 4, 3), @(29, 5, 3, 3),
            @(3, 14, 6, 4), @(0, 18, 4, 3), @(8, 18, 3, 3),
            @(12, 13, 5, 5), @(10, 18, 4, 3), @(16, 17, 3, 3),
            @(21, 14, 6, 5), @(19, 19, 4, 3), @(26, 18, 3, 3),
            @(5, 25, 5, 4), @(3, 29, 4, 3), @(9, 28, 3, 3),
            @(16, 24, 6, 5), @(14, 29, 4, 3), @(21, 28, 3, 3),
            @(26, 25, 5, 5), @(24, 30, 4, 2), @(30, 29, 2, 3)
        )

        Add-MacroPatch $graphics $palette.Light 256 8 @(
            @(0, 0, 4, 2), @(3, 2, 3, 1),
            @(13, 0, 4, 2), @(16, 2, 3, 1),
            @(22, 10, 5, 2), @(26, 12, 3, 1),
            @(5, 11, 5, 2), @(9, 13, 3, 1),
            @(14, 21, 5, 2), @(18, 23, 3, 1),
            @(1, 27, 4, 2), @(4, 29, 3, 1),
            @(27, 15, 4, 2), @(30, 17, 2, 1)
        )

        Add-MacroPatch $graphics $palette.Brown 256 8 @(
            @(6, 2, 3, 4), @(5, 6, 2, 2), @(8, 5, 2, 2),
            @(18, 0, 4, 3), @(17, 3, 2, 2), @(21, 3, 2, 2),
            @(27, 9, 4, 4), @(25, 13, 3, 2), @(30, 12, 2, 3),
            @(1, 20, 4, 4), @(0, 24, 3, 2), @(4, 23, 2, 2),
            @(11, 22, 4, 3), @(10, 25, 3, 2), @(14, 25, 2, 2),
            @(23, 27, 4, 3), @(21, 30, 3, 2), @(27, 29, 2, 3)
        )
    }

    return $bitmap
}

function Save-VariantTextures([System.Drawing.Bitmap]$Master, [string]$Variant, [int]$X, [int]$Y) {
    $tile = $Master.Clone([System.Drawing.Rectangle]::new($X, $Y, 128, 128), $Master.PixelFormat)
    try {
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

Ensure-Dir $textureDir

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
        Y = @{ item = "minecraft:light_gray_dye" }
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
        @{ item = "minecraft:light_gray_dye" }
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
