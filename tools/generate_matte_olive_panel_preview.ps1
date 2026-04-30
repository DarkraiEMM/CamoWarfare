$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$resourcesRoot = Join-Path $root "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"
$dataRoot = Join-Path $resourcesRoot "data"
$previewRoot = Join-Path $root "preview\deep_olive_plate_six_face_concept"

$blockId = "matte_olive_panel_block"
$textureDir = Join-Path $assetsRoot "textures\block\matte_olive_panel"
$blockstatePath = Join-Path $assetsRoot "blockstates\$blockId.json"
$blockModelPath = Join-Path $assetsRoot "models\block\$blockId.json"
$itemModelPath = Join-Path $assetsRoot "models\item\$blockId.json"
$lootPath = Join-Path $dataRoot "camowarfare\loot_tables\blocks\$blockId.json"
$pickaxeTagPath = Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json"
$armoredTagPath = Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json"
$physicsTagPath = Join-Path $dataRoot "camowarfare\tags\block\simulated_physics_blocks.json"

$atlasSize = 512
$tileSize = 128

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

function Clamp-Byte([double]$Value) {
    return [byte][Math]::Max(0, [Math]::Min(255, [int][Math]::Round($Value)))
}

function Blend-Color([System.Drawing.Color]$ColorA, [System.Drawing.Color]$ColorB, [double]$T) {
    $t = [Math]::Max(0.0, [Math]::Min(1.0, $T))
    $red = ($ColorA.R * (1.0 - $t)) + ($ColorB.R * $t)
    $green = ($ColorA.G * (1.0 - $t)) + ($ColorB.G * $t)
    $blue = ($ColorA.B * (1.0 - $t)) + ($ColorB.B * $t)
    return [System.Drawing.Color]::FromArgb($ColorA.A, (Clamp-Byte $red), (Clamp-Byte $green), (Clamp-Byte $blue))
}

function Normalize-EdgeBand([System.Drawing.Bitmap]$Bitmap, [int]$Band, [double]$Blend) {
    $width = $Bitmap.Width
    $height = $Bitmap.Height
    $sampleInset = [Math]::Min(18, [Math]::Max($Band + 2, 10))
    $blend = [Math]::Max(0.0, [Math]::Min(1.0, $Blend))

    for ($x = 0; $x -lt $width; $x++) {
        for ($i = 0; $i -lt $Band; $i++) {
            $topColor = $Bitmap.GetPixel($x, $i)
            $topSample = $Bitmap.GetPixel($x, [Math]::Min($height - 1, $sampleInset + $i))
            $bottomColor = $Bitmap.GetPixel($x, $height - 1 - $i)
            $bottomSample = $Bitmap.GetPixel($x, [Math]::Max(0, $height - 1 - $sampleInset - $i))
            $Bitmap.SetPixel($x, $i, (Blend-Color $topColor $topSample $blend))
            $Bitmap.SetPixel($x, $height - 1 - $i, (Blend-Color $bottomColor $bottomSample $blend))
        }
    }

    for ($y = 0; $y -lt $height; $y++) {
        for ($i = 0; $i -lt $Band; $i++) {
            $leftColor = $Bitmap.GetPixel($i, $y)
            $leftSample = $Bitmap.GetPixel([Math]::Min($width - 1, $sampleInset + $i), $y)
            $rightColor = $Bitmap.GetPixel($width - 1 - $i, $y)
            $rightSample = $Bitmap.GetPixel([Math]::Max(0, $width - 1 - $sampleInset - $i), $y)
            $Bitmap.SetPixel($i, $y, (Blend-Color $leftColor $leftSample $blend))
            $Bitmap.SetPixel($width - 1 - $i, $y, (Blend-Color $rightColor $rightSample $blend))
        }
    }
}

function Get-ColumnVariation([System.Drawing.Bitmap]$Bitmap, [int]$X) {
    $values = [System.Collections.Generic.List[double]]::new()
    for ($y = 0; $y -lt $Bitmap.Height; $y += 4) {
        $color = $Bitmap.GetPixel($X, $y)
        $values.Add((($color.R + $color.G + $color.B) / 3.0))
    }
    $avg = ($values | Measure-Object -Average).Average
    $variance = 0.0
    foreach ($value in $values) {
        $variance += [Math]::Pow(($value - $avg), 2)
    }
    return [Math]::Sqrt($variance / [Math]::Max(1, $values.Count))
}

function Find-TrimmedRight([System.Drawing.Bitmap]$Bitmap) {
    $threshold = 2.0
    for ($x = $Bitmap.Width - 1; $x -ge 0; $x--) {
        if ((Get-ColumnVariation $Bitmap $x) -gt $threshold) {
            return [Math]::Min($Bitmap.Width, $x + 4)
        }
    }
    return $Bitmap.Width
}

function Find-TrimmedLeft([System.Drawing.Bitmap]$Bitmap) {
    $threshold = 2.0
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
        if ((Get-ColumnVariation $Bitmap $x) -gt $threshold) {
            return [Math]::Max(0, $x - 1)
        }
    }
    return 0
}

function Load-PreparedFace([string]$SourcePath, [switch]$TrimSides) {
    $bitmap = [System.Drawing.Bitmap]::new($SourcePath)
    try {
        if ($TrimSides) {
            $left = Find-TrimmedLeft $bitmap
            $right = Find-TrimmedRight $bitmap
            $width = [Math]::Max(1, $right - $left)
            $cropped = $bitmap.Clone([System.Drawing.Rectangle]::new($left, 0, $width, $bitmap.Height), $bitmap.PixelFormat)
            try {
                $prepared = [System.Drawing.Bitmap]::new($tileSize, $tileSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                $graphics = [System.Drawing.Graphics]::FromImage($prepared)
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                try {
                    $graphics.DrawImage($cropped, [System.Drawing.Rectangle]::new(0, 0, $tileSize, $tileSize))
                }
                finally {
                    $graphics.Dispose()
                }
                Normalize-EdgeBand $prepared 4 0.55
                return $prepared
            }
            finally {
                $cropped.Dispose()
            }
        } else {
            $prepared = [System.Drawing.Bitmap]::new($tileSize, $tileSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [System.Drawing.Graphics]::FromImage($prepared)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            try {
                $graphics.DrawImage($bitmap, [System.Drawing.Rectangle]::new(0, 0, $tileSize, $tileSize))
            }
            finally {
                $graphics.Dispose()
            }
            Normalize-EdgeBand $prepared 4 0.35
            return $prepared
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

function Flatten-Edge([System.Drawing.Bitmap]$Bitmap, [string]$Edge, [int]$Band, [double]$Blend) {
    $width = $Bitmap.Width
    $height = $Bitmap.Height
    $blend = [Math]::Max(0.0, [Math]::Min(1.0, $Blend))
    $sampleInset = [Math]::Max(($Band * 2) + 6, $Band + 12)

    switch ($Edge) {
        "top" {
            for ($y = 0; $y -lt $Band; $y++) {
                $sampleY = [Math]::Min($height - 1, $sampleInset + $y)
                for ($x = 0; $x -lt $width; $x++) {
                    $Bitmap.SetPixel($x, $y, (Blend-Color $Bitmap.GetPixel($x, $y) $Bitmap.GetPixel($x, $sampleY) $blend))
                }
            }
        }
        "bottom" {
            for ($y = 0; $y -lt $Band; $y++) {
                $targetY = $height - 1 - $y
                $sampleY = [Math]::Max(0, $height - 1 - $sampleInset - $y)
                for ($x = 0; $x -lt $width; $x++) {
                    $Bitmap.SetPixel($x, $targetY, (Blend-Color $Bitmap.GetPixel($x, $targetY) $Bitmap.GetPixel($x, $sampleY) $blend))
                }
            }
        }
        "left" {
            for ($x = 0; $x -lt $Band; $x++) {
                $sampleX = [Math]::Min($width - 1, $sampleInset + $x)
                for ($y = 0; $y -lt $height; $y++) {
                    $Bitmap.SetPixel($x, $y, (Blend-Color $Bitmap.GetPixel($x, $y) $Bitmap.GetPixel($sampleX, $y) $blend))
                }
            }
        }
        "right" {
            for ($x = 0; $x -lt $Band; $x++) {
                $targetX = $width - 1 - $x
                $sampleX = [Math]::Max(0, $width - 1 - $sampleInset - $x)
                for ($y = 0; $y -lt $height; $y++) {
                    $Bitmap.SetPixel($targetX, $y, (Blend-Color $Bitmap.GetPixel($targetX, $y) $Bitmap.GetPixel($sampleX, $y) $blend))
                }
            }
        }
    }
}

function Create-ConnectedTile(
    [System.Drawing.Bitmap]$BaseTile,
    [bool]$TopConnected,
    [bool]$RightConnected,
    [bool]$BottomConnected,
    [bool]$LeftConnected,
    [hashtable]$Config
) {
    $tile = $BaseTile.Clone([System.Drawing.Rectangle]::new(0, 0, $BaseTile.Width, $BaseTile.Height), $BaseTile.PixelFormat)
    if ($TopConnected) { Flatten-Edge $tile "top" $Config.TopBand $Config.Blend }
    if ($RightConnected) { Flatten-Edge $tile "right" $Config.RightBand $Config.Blend }
    if ($BottomConnected) { Flatten-Edge $tile "bottom" $Config.BottomBand $Config.Blend }
    if ($LeftConnected) { Flatten-Edge $tile "left" $Config.LeftBand $Config.Blend }
    return $tile
}

function Get-AverageAlpha([System.Drawing.Bitmap]$Bitmap) {
    $sum = 0.0
    $count = 0
    for ($y = 0; $y -lt $Bitmap.Height; $y += 8) {
        for ($x = 0; $x -lt $Bitmap.Width; $x += 8) {
            $sum += $Bitmap.GetPixel($x, $y).A
            $count++
        }
    }
    return $sum / [Math]::Max(1, $count)
}

function Build-Atlas([string]$SourceFile, [string]$DestinationName, [hashtable]$Config, [switch]$TrimSides) {
    $baseTile = Load-PreparedFace (Join-Path $previewRoot $SourceFile) -TrimSides:$TrimSides
    try {
        $atlas = [System.Drawing.Bitmap]::new($atlasSize, $atlasSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($atlas)
        try {
            for ($mask = 0; $mask -lt 16; $mask++) {
                $top = ($mask -band 1) -ne 0
                $right = ($mask -band 2) -ne 0
                $bottom = ($mask -band 4) -ne 0
                $left = ($mask -band 8) -ne 0
                $tile = Create-ConnectedTile $baseTile $top $right $bottom $left $Config
                if ((Get-AverageAlpha $tile) -lt 1.0) {
                    $tile.Dispose()
                    $tile = $baseTile.Clone([System.Drawing.Rectangle]::new(0, 0, $baseTile.Width, $baseTile.Height), $baseTile.PixelFormat)
                }
                try {
                    $col = $mask % 4
                    $row = [int][Math]::Floor($mask / 4)
                    $graphics.DrawImage($tile, [System.Drawing.Rectangle]::new($col * $tileSize, $row * $tileSize, $tileSize, $tileSize))
                }
                finally {
                    $tile.Dispose()
                }
            }
        }
        finally {
            $graphics.Dispose()
        }

        Ensure-Dir $textureDir
        $atlas.Save((Join-Path $textureDir "$DestinationName.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $baseTile.Dispose()
        if ($atlas) { $atlas.Dispose() }
    }
}

function Save-Particle([string]$SourceFile) {
    $particle = Load-PreparedFace (Join-Path $previewRoot $SourceFile)
    try {
        Ensure-Dir $textureDir
        $particle.Save((Join-Path $textureDir "particle.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $particle.Dispose()
    }
}

function Export-SplitMaskTextures([string]$AtlasName) {
    $atlasPath = Join-Path $textureDir ($AtlasName + ".png")
    $bitmap = [System.Drawing.Bitmap]::new($atlasPath)
    try {
        $tileWidth = [int]($bitmap.Width / 4)
        $tileHeight = [int]($bitmap.Height / 4)
        for ($mask = 0; $mask -lt 16; $mask++) {
            $col = $mask % 4
            $row = [int][Math]::Floor($mask / 4)
            $rect = [System.Drawing.Rectangle]::new($col * $tileWidth, $row * $tileHeight, $tileWidth, $tileHeight)
            $tile = $bitmap.Clone($rect, $bitmap.PixelFormat)
            try {
                $tile.Save((Join-Path $textureDir ($AtlasName + "_m" + $mask + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
            }
            finally {
                $tile.Dispose()
            }
        }
    }
    finally {
        $bitmap.Dispose()
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

$sideConfig = @{
    TopBand = 24
    RightBand = 12
    BottomBand = 28
    LeftBand = 12
    Blend = 1.0
}

$topConfig = @{
    TopBand = 18
    RightBand = 18
    BottomBand = 18
    LeftBand = 18
    Blend = 1.0
}

Build-Atlas "front_ref_512_clean.png" "north_atlas" $sideConfig
Build-Atlas "front_ref_512_clean.png" "south_atlas" $sideConfig
Build-Atlas "front_ref_512_clean.png" "west_atlas" $sideConfig
Build-Atlas "front_ref_512_clean.png" "east_atlas" $sideConfig
Build-Atlas "top_ref_512.png" "up_atlas" $topConfig
Build-Atlas "bottom_ref_512.png" "down_atlas" $topConfig
Save-Particle "front_ref_512_clean.png"
foreach ($atlasName in @("north_atlas", "south_atlas", "west_atlas", "east_atlas", "up_atlas", "down_atlas")) {
    Export-SplitMaskTextures $atlasName
}

Save-Json $blockstatePath @{
    variants = @{
        "" = @{
            model = "camowarfare:block/$blockId"
        }
    }
}

Save-Json $blockModelPath @{
    render_type = "minecraft:solid"
    ambientocclusion = $true
    parent = "minecraft:block/block"
    textures = @{
        atlas = "camowarfare:block/matte_olive_panel/north_atlas"
        north = "camowarfare:block/matte_olive_panel/north_atlas"
        south = "camowarfare:block/matte_olive_panel/south_atlas"
        west = "camowarfare:block/matte_olive_panel/west_atlas"
        east = "camowarfare:block/matte_olive_panel/east_atlas"
        up = "camowarfare:block/matte_olive_panel/up_atlas"
        down = "camowarfare:block/matte_olive_panel/down_atlas"
        particle = "camowarfare:block/matte_olive_panel/particle"
    }
    loader = "camowarfare:connected_camo"
}

Save-Json $itemModelPath @{
    render_type = "minecraft:solid"
    ambientocclusion = $true
    parent = "minecraft:block/block"
    item_render = $true
    textures = @{
        atlas = "camowarfare:block/matte_olive_panel/north_atlas"
        north = "camowarfare:block/matte_olive_panel/north_atlas"
        south = "camowarfare:block/matte_olive_panel/south_atlas"
        west = "camowarfare:block/matte_olive_panel/west_atlas"
        east = "camowarfare:block/matte_olive_panel/east_atlas"
        up = "camowarfare:block/matte_olive_panel/up_atlas"
        down = "camowarfare:block/matte_olive_panel/down_atlas"
        particle = "camowarfare:block/matte_olive_panel/particle"
    }
    loader = "camowarfare:connected_camo"
}

Save-Json $lootPath @{
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

foreach ($tagPath in @($pickaxeTagPath, $armoredTagPath, $physicsTagPath)) {
    Ensure-TagValue $tagPath "camowarfare:$blockId"
}

Write-Output "Generated connected atlas resources for $blockId"
