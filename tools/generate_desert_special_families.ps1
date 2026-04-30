$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$resourcesRoot = Join-Path $root "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"
$dataRoot = Join-Path $resourcesRoot "data"

$blockTextureRoot = Join-Path $assetsRoot "textures\block"
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

$families = @(
    @{
        Id = "desert_modern"
        Style = "pmc"
        MixDye = "minecraft:brown_dye"
        Palette = @{
            Base = [System.Drawing.ColorTranslator]::FromHtml("#C4A779")
            Light = [System.Drawing.ColorTranslator]::FromHtml("#DEC798")
            Tan = [System.Drawing.ColorTranslator]::FromHtml("#A98B61")
            Brown = [System.Drawing.ColorTranslator]::FromHtml("#7B5F3F")
            Dust = [System.Drawing.ColorTranslator]::FromHtml("#D2BB8B")
        }
    },
    @{
        Id = "desert_brush"
        Style = "british"
        MixDye = "minecraft:yellow_dye"
        Palette = @{
            Base = [System.Drawing.ColorTranslator]::FromHtml("#CBB48B")
            Light = [System.Drawing.ColorTranslator]::FromHtml("#E2D1AB")
            Sand = [System.Drawing.ColorTranslator]::FromHtml("#B29468")
            Brown = [System.Drawing.ColorTranslator]::FromHtml("#8A6A45")
            Stone = [System.Drawing.ColorTranslator]::FromHtml("#9D8665")
        }
    }
)

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

function Fill-WrappedPolygon(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Color]$Color,
    [System.Drawing.PointF[]]$Points,
    [int]$TileSize
) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        foreach ($offsetX in @(-$TileSize, 0, $TileSize)) {
            foreach ($offsetY in @(-$TileSize, 0, $TileSize)) {
                $shifted = foreach ($point in $Points) {
                    [System.Drawing.PointF]::new($point.X + $offsetX, $point.Y + $offsetY)
                }
                $Graphics.FillPolygon($brush, $shifted)
            }
        }
    }
    finally {
        $brush.Dispose()
    }
}

function New-IrregularPatch(
    [System.Random]$Random,
    [double]$CenterX,
    [double]$CenterY,
    [double]$RadiusX,
    [double]$RadiusY,
    [int]$PointCount
) {
    $points = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
    $angleOffset = $Random.NextDouble() * [Math]::PI * 2.0
    for ($index = 0; $index -lt $PointCount; $index++) {
        $angle = $angleOffset + (($index / [double]$PointCount) * [Math]::PI * 2.0)
        $jitterX = 0.74 + ($Random.NextDouble() * 0.34)
        $jitterY = 0.74 + ($Random.NextDouble() * 0.34)
        $x = $CenterX + ([Math]::Cos($angle) * $RadiusX * $jitterX)
        $y = $CenterY + ([Math]::Sin($angle) * $RadiusY * $jitterY)
        $points.Add([System.Drawing.PointF]::new([float]$x, [float]$y))
    }
    return $points.ToArray()
}

function New-BandPolygon(
    [double]$CenterX,
    [double]$CenterY,
    [double]$Length,
    [double]$Thickness,
    [double]$Angle,
    [double]$TailFactor,
    [double]$TipFactor
) {
    $dirX = [Math]::Cos($Angle)
    $dirY = [Math]::Sin($Angle)
    $perpX = -$dirY
    $perpY = $dirX
    $half = $Thickness / 2.0

    return @(
        [System.Drawing.PointF]::new([float]($CenterX - $dirX * $Length * $TailFactor - $perpX * $half), [float]($CenterY - $dirY * $Length * $TailFactor - $perpY * $half)),
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length * $TipFactor - $perpX * ($half * 0.48)), [float]($CenterY + $dirY * $Length * $TipFactor - $perpY * ($half * 0.48))),
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length), [float]($CenterY + $dirY * $Length)),
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length * $TipFactor + $perpX * ($half * 0.48)), [float]($CenterY + $dirY * $Length * $TipFactor + $perpY * ($half * 0.48))),
        [System.Drawing.PointF]::new([float]($CenterX - $dirX * $Length * $TailFactor + $perpX * $half), [float]($CenterY - $dirY * $Length * $TailFactor + $perpY * $half))
    )
}

function Draw-PmcPattern([System.Drawing.Graphics]$Graphics, [System.Random]$Random, $Palette) {
    $Graphics.Clear($Palette.Base)
    foreach ($spec in @(
        @{ Color = $Palette.Light; Count = 4; MinR = 40; MaxR = 76; Aspect = 1.8 },
        @{ Color = $Palette.Tan; Count = 5; MinR = 34; MaxR = 70; Aspect = 1.6 },
        @{ Color = $Palette.Brown; Count = 3; MinR = 22; MaxR = 46; Aspect = 1.4 }
    )) {
        for ($i = 0; $i -lt $spec.Count; $i++) {
            $radius = $spec.MinR + ($Random.NextDouble() * ($spec.MaxR - $spec.MinR))
            $patch = New-IrregularPatch `
                -Random $Random `
                -CenterX (24 + $Random.NextDouble() * 208) `
                -CenterY (24 + $Random.NextDouble() * 208) `
                -RadiusX ($radius * $spec.Aspect) `
                -RadiusY $radius `
                -PointCount (6 + $Random.Next(3))
            Fill-WrappedPolygon $Graphics $spec.Color $patch 256
        }
    }

    for ($i = 0; $i -lt 20; $i++) {
        $x = $Random.Next(32) * 8
        $y = $Random.Next(32) * 8
        $w = (1 + $Random.Next(3)) * 8
        $h = (1 + $Random.Next(2)) * 8
        $color = if ($Random.NextDouble() -gt 0.5) { $Palette.Dust } else { $Palette.Tan }
        Fill-WrappedRect $Graphics $color $x $y $w $h 256
    }
}

function Draw-BritishPattern([System.Drawing.Graphics]$Graphics, [System.Random]$Random, $Palette) {
    $Graphics.Clear($Palette.Base)

    for ($i = 0; $i -lt 6; $i++) {
        $band = New-BandPolygon `
            -CenterX (20 + $Random.NextDouble() * 216) `
            -CenterY (16 + $Random.NextDouble() * 224) `
            -Length (54 + $Random.NextDouble() * 46) `
            -Thickness (18 + $Random.NextDouble() * 12) `
            -Angle (($Random.NextDouble() * 1.0) - 0.22) `
            -TailFactor (0.48 + $Random.NextDouble() * 0.18) `
            -TipFactor (0.50 + $Random.NextDouble() * 0.12)
        Fill-WrappedPolygon $Graphics $Palette.Light $band 256
    }

    for ($i = 0; $i -lt 7; $i++) {
        $band = New-BandPolygon `
            -CenterX (18 + $Random.NextDouble() * 220) `
            -CenterY (18 + $Random.NextDouble() * 220) `
            -Length (48 + $Random.NextDouble() * 42) `
            -Thickness (14 + $Random.NextDouble() * 10) `
            -Angle (($Random.NextDouble() * 1.18) - 0.28) `
            -TailFactor (0.46 + $Random.NextDouble() * 0.16) `
            -TipFactor (0.46 + $Random.NextDouble() * 0.14)
        Fill-WrappedPolygon $Graphics $Palette.Sand $band 256
    }

    for ($i = 0; $i -lt 5; $i++) {
        $band = New-BandPolygon `
            -CenterX (20 + $Random.NextDouble() * 216) `
            -CenterY (16 + $Random.NextDouble() * 224) `
            -Length (34 + $Random.NextDouble() * 32) `
            -Thickness (10 + $Random.NextDouble() * 8) `
            -Angle (($Random.NextDouble() * 1.24) - 0.32) `
            -TailFactor (0.44 + $Random.NextDouble() * 0.12) `
            -TipFactor (0.44 + $Random.NextDouble() * 0.10)
        Fill-WrappedPolygon $Graphics $Palette.Brown $band 256
    }

    for ($i = 0; $i -lt 14; $i++) {
        $patch = New-IrregularPatch `
            -Random $Random `
            -CenterX (20 + $Random.NextDouble() * 216) `
            -CenterY (20 + $Random.NextDouble() * 216) `
            -RadiusX (10 + $Random.NextDouble() * 18) `
            -RadiusY (6 + $Random.NextDouble() * 12) `
            -PointCount (5 + $Random.Next(2))
        Fill-WrappedPolygon $Graphics $Palette.Stone $patch 256
    }
}

function New-MasterPattern($Family) {
    $bitmap = New-Bitmap 256 256
    $random = New-SeedRandom $Family.Id
    Use-Graphics $bitmap {
        param($graphics)
        switch ($Family.Style) {
            "pmc" { Draw-PmcPattern $graphics $random $Family.Palette }
            "british" { Draw-BritishPattern $graphics $random $Family.Palette }
        }
    }
    return $bitmap
}

function Save-VariantTextures([string]$FamilyId, [System.Drawing.Bitmap]$Master, [string]$Variant, [int]$X, [int]$Y) {
    $tile = $Master.Clone([System.Drawing.Rectangle]::new($X, $Y, 128, 128), $Master.PixelFormat)
    try {
        $textureDir = Join-Path $blockTextureRoot $FamilyId
        Ensure-Dir $textureDir
        $tile.Save((Join-Path $textureDir ($Variant + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
        $tile.Save((Join-Path $textureDir ($Variant + "_atlas.png")), [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $tile.Dispose()
    }
}

function Write-BlockResources([string]$FamilyId, [string]$Variant) {
    $blockId = "${FamilyId}_${Variant}_block"
    $textureRef = "camowarfare:block/${FamilyId}/${Variant}_atlas"

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

foreach ($family in $families) {
    $master = New-MasterPattern $family
    try {
        Save-VariantTextures $family.Id $master "a" 0 0
        Save-VariantTextures $family.Id $master "b" 128 0
        Save-VariantTextures $family.Id $master "c" 0 128
        Save-VariantTextures $family.Id $master "d" 128 128
    }
    finally {
        $master.Dispose()
    }

    foreach ($variant in @("a", "b", "c", "d")) {
        Write-BlockResources $family.Id $variant
    }

    Save-Json (Join-Path $recipeOriginalRoot ($family.Id + "_a_block.json")) @{
        type = "minecraft:crafting_shaped"
        category = "building"
        pattern = @("XXX", "XYX", "XXX")
        key = @{
            X = @{ item = "camowarfare:solid_desert_sand_a_block" }
            Y = @{ item = $family.MixDye }
        }
        result = @{
            id = "camowarfare:$($family.Id)_a_block"
            count = 8
        }
    }

    Save-Json (Join-Path $recipeCreateMixingRoot ($family.Id + "_a_block.json")) @{
        "neoforge:conditions" = @(
            @{
                type = "neoforge:mod_loaded"
                modid = "create"
            }
        )
        type = "create:mixing"
        ingredients = @(
            @{ item = "camowarfare:solid_desert_sand_a_block" },
            @{ item = "camowarfare:solid_desert_sand_a_block" },
            @{ item = "camowarfare:solid_desert_sand_a_block" },
            @{ item = "camowarfare:solid_desert_sand_a_block" },
            @{ item = "camowarfare:solid_desert_sand_a_block" },
            @{ item = "camowarfare:solid_desert_sand_a_block" },
            @{ item = "camowarfare:solid_desert_sand_a_block" },
            @{ item = "camowarfare:solid_desert_sand_a_block" },
            @{ item = $family.MixDye }
        )
        results = @(
            @{
                id = "camowarfare:$($family.Id)_a_block"
                count = 8
            }
        )
    }

    foreach ($to in @("a", "b", "c", "d")) {
        foreach ($from in @("a", "b", "c", "d")) {
            if ($to -eq $from) { continue }
            $recipeName = "$($family.Id)_${to}_from_${from}.json"
            $sourceBlock = "camowarfare:$($family.Id)_${from}_block"
            $targetBlock = "camowarfare:$($family.Id)_${to}_block"

            Save-Json (Join-Path $recipeStonecuttingRoot $recipeName) @{
                type = "minecraft:stonecutting"
                ingredient = @{ item = $sourceBlock }
                result = @{ id = $targetBlock; count = 1 }
            }

            Save-Json (Join-Path $recipeCreateCuttingRoot $recipeName) @{
                "neoforge:conditions" = @(
                    @{ type = "neoforge:mod_loaded"; modid = "create" }
                )
                type = "create:cutting"
                ingredients = @(
                    @{ item = $sourceBlock }
                )
                processing_time = 50
                results = @(
                    @{ id = $targetBlock; count = 1 }
                )
            }
        }
    }

    foreach ($variant in @("a", "b", "c", "d")) {
        $entry = "camowarfare:$($family.Id)_${variant}_block"
        Ensure-TagValue $pickaxeTagPath $entry
        Ensure-TagValue $armoredTagPath $entry
    }
}

Write-Output "special desert families generated"
