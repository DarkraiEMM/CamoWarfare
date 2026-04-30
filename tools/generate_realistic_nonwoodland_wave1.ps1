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
$previewRoot = Join-Path $root "preview\nonwoodland_wave1"

function Ensure-Dir([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function New-Bitmap([int]$Width, [int]$Height) {
    return [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
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

function Draw-WrappedLine(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Color]$Color,
    [float]$X1,
    [float]$Y1,
    [float]$X2,
    [float]$Y2,
    [float]$Width,
    [int]$TileSize
) {
    $pen = [System.Drawing.Pen]::new($Color, $Width)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Square
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Square
    try {
        foreach ($offsetX in @(-$TileSize, 0, $TileSize)) {
            foreach ($offsetY in @(-$TileSize, 0, $TileSize)) {
                $Graphics.DrawLine($pen, $X1 + $offsetX, $Y1 + $offsetY, $X2 + $offsetX, $Y2 + $offsetY)
            }
        }
    }
    finally {
        $pen.Dispose()
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
    [float]$CenterX,
    [float]$CenterY,
    [float]$RadiusX,
    [float]$RadiusY,
    [int]$PointCount
) {
    $points = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    $angleOffset = $Random.NextDouble() * [Math]::PI * 2.0

    for ($index = 0; $index -lt $PointCount; $index++) {
        $angle = $angleOffset + (($index / [double]$PointCount) * [Math]::PI * 2.0)
        $jitterX = 0.72 + ($Random.NextDouble() * 0.48)
        $jitterY = 0.72 + ($Random.NextDouble() * 0.48)
        $x = $CenterX + ([Math]::Cos($angle) * $RadiusX * $jitterX)
        $y = $CenterY + ([Math]::Sin($angle) * $RadiusY * $jitterY)
        $points.Add([System.Drawing.PointF]::new([float]$x, [float]$y))
    }

    return $points.ToArray()
}

function Add-LargePatchLayer(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$TileSize,
    [int]$Count,
    [double]$RadiusMin,
    [double]$RadiusMax,
    [double]$AspectMin,
    [double]$AspectMax
) {
    for ($i = 0; $i -lt $Count; $i++) {
        $centerX = $Random.NextDouble() * $TileSize
        $centerY = $Random.NextDouble() * $TileSize
        $radius = $RadiusMin + ($Random.NextDouble() * ($RadiusMax - $RadiusMin))
        $aspect = $AspectMin + ($Random.NextDouble() * ($AspectMax - $AspectMin))

        if ($Random.NextDouble() -gt 0.5) {
            $radiusX = $radius * $aspect
            $radiusY = $radius
        }
        else {
            $radiusX = $radius
            $radiusY = $radius * $aspect
        }

        $points = New-IrregularPatch -Random $Random -CenterX $centerX -CenterY $centerY -RadiusX $radiusX -RadiusY $radiusY -PointCount (7 + $Random.Next(5))
        Fill-WrappedPolygon -Graphics $Graphics -Color $Color -Points $points -TileSize $TileSize
    }
}

function Add-DigitalLayer(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$TileSize,
    [int]$CellSize,
    [int]$ClusterCount,
    [int]$MinCells,
    [int]$MaxCells
) {
    for ($cluster = 0; $cluster -lt $ClusterCount; $cluster++) {
        $cells = $MinCells + $Random.Next([Math]::Max(1, $MaxCells - $MinCells + 1))
        $originX = $Random.Next([Math]::Max(1, [int]($TileSize / $CellSize)))
        $originY = $Random.Next([Math]::Max(1, [int]($TileSize / $CellSize)))

        for ($index = 0; $index -lt $cells; $index++) {
            $dx = $originX + ($Random.Next(-2, 3)) + [Math]::Floor($index / 3)
            $dy = $originY + ($Random.Next(-2, 3))
            $x = (($dx * $CellSize) % $TileSize + $TileSize) % $TileSize
            $y = (($dy * $CellSize) % $TileSize + $TileSize) % $TileSize
            Fill-WrappedRect -Graphics $Graphics -Color $Color -X $x -Y $y -Width $CellSize -Height $CellSize -TileSize $TileSize
        }
    }
}

function Add-SplinterLayer(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$TileSize,
    [int]$Count
) {
    for ($index = 0; $index -lt $Count; $index++) {
        $centerX = $Random.NextDouble() * $TileSize
        $centerY = $Random.NextDouble() * $TileSize
        $length = 52 + $Random.Next(44)
        $width = 18 + $Random.Next(22)
        $angle = ($Random.NextDouble() * 0.9) - 0.45
        $tip = [System.Drawing.PointF]::new([float]($centerX + ($length * [Math]::Cos($angle))), [float]($centerY + ($length * [Math]::Sin($angle))))
        $baseLeft = [System.Drawing.PointF]::new([float]($centerX - ($width * [Math]::Sin($angle))), [float]($centerY + ($width * [Math]::Cos($angle))))
        $baseRight = [System.Drawing.PointF]::new([float]($centerX + ($width * [Math]::Sin($angle))), [float]($centerY - ($width * [Math]::Cos($angle))))
        $tail = [System.Drawing.PointF]::new([float]($centerX - ($length * 0.45 * [Math]::Cos($angle))), [float]($centerY - ($length * 0.45 * [Math]::Sin($angle))))
        $points = @($baseLeft, $tip, $baseRight, $tail)
        Fill-WrappedPolygon -Graphics $Graphics -Color $Color -Points $points -TileSize $TileSize
    }
}

function Draw-FamilyMasterPattern(
    [System.Drawing.Bitmap]$Bitmap,
    [hashtable]$Family
) {
    $tileSize = $Bitmap.Width
    $baseRandom = New-SeedRandom "$($Family.Id)-master"

    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($Family.Palette[0])

        switch ($Family.Style) {
            "base" {
                Add-LargePatchLayer -Graphics $Graphics -Random $baseRandom -Color $Family.Palette[1] -TileSize $tileSize -Count 10 -RadiusMin ($tileSize * 0.12) -RadiusMax ($tileSize * 0.19) -AspectMin 1.2 -AspectMax 2.0
                Add-LargePatchLayer -Graphics $Graphics -Random $baseRandom -Color $Family.Palette[2] -TileSize $tileSize -Count 8 -RadiusMin ($tileSize * 0.10) -RadiusMax ($tileSize * 0.17) -AspectMin 1.1 -AspectMax 1.8
                Add-LargePatchLayer -Graphics $Graphics -Random $baseRandom -Color $Family.Palette[3] -TileSize $tileSize -Count 4 -RadiusMin ($tileSize * 0.09) -RadiusMax ($tileSize * 0.14) -AspectMin 1.1 -AspectMax 1.7
            }
            "digital" {
                $cell = [Math]::Max(16, [int]($tileSize / 32))
                Add-DigitalLayer -Graphics $Graphics -Random $baseRandom -Color $Family.Palette[1] -TileSize $tileSize -CellSize $cell -ClusterCount 14 -MinCells 12 -MaxCells 28
                Add-DigitalLayer -Graphics $Graphics -Random $baseRandom -Color $Family.Palette[2] -TileSize $tileSize -CellSize $cell -ClusterCount 10 -MinCells 10 -MaxCells 22
                Add-DigitalLayer -Graphics $Graphics -Random $baseRandom -Color $Family.Palette[3] -TileSize $tileSize -CellSize $cell -ClusterCount 6 -MinCells 8 -MaxCells 18
            }
            "splinter" {
                Add-SplinterLayer -Graphics $Graphics -Random $baseRandom -Color $Family.Palette[1] -TileSize $tileSize -Count 10
                Add-SplinterLayer -Graphics $Graphics -Random $baseRandom -Color $Family.Palette[2] -TileSize $tileSize -Count 8
                Add-SplinterLayer -Graphics $Graphics -Random $baseRandom -Color $Family.Palette[3] -TileSize $tileSize -Count 5
            }
        }
    }
}

function Copy-Quadrant(
    [System.Drawing.Bitmap]$Source,
    [int]$SourceX,
    [int]$SourceY,
    [int]$SourceSize,
    [int]$OutputSize
) {
    $target = New-Bitmap $OutputSize $OutputSize
    Use-Graphics $target {
        param($Graphics)
        $Graphics.DrawImage(
            $Source,
            [System.Drawing.Rectangle]::new(0, 0, $OutputSize, $OutputSize),
            [System.Drawing.Rectangle]::new($SourceX, $SourceY, $SourceSize, $SourceSize),
            [System.Drawing.GraphicsUnit]::Pixel
        )
    }
    return $target
}

$families = @(
    @{ Id = "naval_bluegray_camo"; PreviewLabel = "Naval Blue-Gray Camo"; Style = "base"; Palette = @((ConvertTo-Color "#44505B"), (ConvertTo-Color "#5D6C7A"), (ConvertTo-Color "#2E3945"), (ConvertTo-Color "#1B232C")) },
    @{ Id = "naval_bluegray_digital"; PreviewLabel = "Naval Blue-Gray Digital"; Style = "digital"; Palette = @((ConvertTo-Color "#46515D"), (ConvertTo-Color "#5F6E7C"), (ConvertTo-Color "#303C48"), (ConvertTo-Color "#1C252E")) },
    @{ Id = "naval_bluegray_splinter"; PreviewLabel = "Naval Blue-Gray Splinter"; Style = "splinter"; Palette = @((ConvertTo-Color "#43505C"), (ConvertTo-Color "#5C6A79"), (ConvertTo-Color "#2D3844"), (ConvertTo-Color "#1A232C")) },
    @{ Id = "night_lowvis_camo"; PreviewLabel = "Night Low-Vis"; Style = "base"; Palette = @((ConvertTo-Color "#20252A"), (ConvertTo-Color "#404852"), (ConvertTo-Color "#2C333B"), (ConvertTo-Color "#12171C")) },
    @{ Id = "night_lowvis_digital"; PreviewLabel = "Night Low-Vis Digital"; Style = "digital"; Palette = @((ConvertTo-Color "#22282E"), (ConvertTo-Color "#434C56"), (ConvertTo-Color "#2E363E"), (ConvertTo-Color "#151A1F")) },
    @{ Id = "night_lowvis_splinter"; PreviewLabel = "Night Low-Vis Splinter"; Style = "splinter"; Palette = @((ConvertTo-Color "#1E2328"), (ConvertTo-Color "#3E4852"), (ConvertTo-Color "#293038"), (ConvertTo-Color "#10151A")) },
    @{ Id = "snow_graywhite_camo"; PreviewLabel = "Snow Gray-White Camo"; Style = "base"; Palette = @((ConvertTo-Color "#E6EBE8"), (ConvertTo-Color "#F7F9F8"), (ConvertTo-Color "#BDC5CB"), (ConvertTo-Color "#9DA7AE")) },
    @{ Id = "snow_graywhite_digital"; PreviewLabel = "Snow Gray-White Digital"; Style = "digital"; Palette = @((ConvertTo-Color "#E3E8E6"), (ConvertTo-Color "#F8FAF9"), (ConvertTo-Color "#C2CAD0"), (ConvertTo-Color "#A1ABB2")) },
    @{ Id = "snow_graywhite_splinter"; PreviewLabel = "Snow Gray-White Splinter"; Style = "splinter"; Palette = @((ConvertTo-Color "#E0E6E3"), (ConvertTo-Color "#F9FBFA"), (ConvertTo-Color "#C0C8CE"), (ConvertTo-Color "#9EA8B0")) },
    @{ Id = "urban_gray_camo"; PreviewLabel = "Urban Gray Camo"; Style = "base"; Palette = @((ConvertTo-Color "#757A80"), (ConvertTo-Color "#98A0A6"), (ConvertTo-Color "#555C63"), (ConvertTo-Color "#3A4148")) },
    @{ Id = "urban_gray_digital"; PreviewLabel = "Urban Gray Digital"; Style = "digital"; Palette = @((ConvertTo-Color "#747980"), (ConvertTo-Color "#9AA2A8"), (ConvertTo-Color "#586068"), (ConvertTo-Color "#3C444C")) },
    @{ Id = "urban_gray_splinter"; PreviewLabel = "Urban Gray Splinter"; Style = "splinter"; Palette = @((ConvertTo-Color "#737980"), (ConvertTo-Color "#949DA5"), (ConvertTo-Color "#565E65"), (ConvertTo-Color "#394149")) }
)

Ensure-Dir $previewRoot

$sheetRows = 4
$sheetCols = 3
$cellSize = 320
$sheet = New-Bitmap ($sheetCols * $cellSize) ($sheetRows * ($cellSize + 32))
try {
    Use-Graphics $sheet {
        param($Graphics)
        $Graphics.Clear((ConvertTo-Color "#1B1E23"))
    }

    for ($index = 0; $index -lt $families.Count; $index++) {
        $family = $families[$index]

        $master = New-Bitmap 2048 2048
        try {
            Draw-FamilyMasterPattern -Bitmap $master -Family $family

            $preview = New-Bitmap 512 512
            try {
                Use-Graphics $preview {
                    param($Graphics)
                    $Graphics.DrawImage(
                        $master,
                        [System.Drawing.Rectangle]::new(0, 0, 512, 512),
                        [System.Drawing.Rectangle]::new(0, 0, 2048, 2048),
                        [System.Drawing.GraphicsUnit]::Pixel
                    )
                }
                Save-Png $preview (Join-Path $previewRoot ($family.Id + "_preview.png"))

                $row = [Math]::Floor($index / $sheetCols)
                $col = $index % $sheetCols
                $x = $col * $cellSize
                $y = $row * ($cellSize + 32)

                Use-Graphics $sheet {
                    param($Graphics)
                    $Graphics.DrawImage($preview, $x + 8, $y + 8, $cellSize - 16, $cellSize - 16)
                    $font = [System.Drawing.Font]::new("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Regular)
                    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(235, 230, 232, 235))
                    try {
                        $Graphics.DrawString($family.PreviewLabel, $font, $brush, $x + 8, $y + $cellSize - 6)
                    }
                    finally {
                        $brush.Dispose()
                        $font.Dispose()
                    }
                }
            }
            finally {
                $preview.Dispose()
            }

            $familyDir = Join-Path $blockTextureRoot $family.Id
            Ensure-Dir $familyDir

            $quadrants = @{
                "a" = @{ X = 0; Y = 0 }
                "b" = @{ X = 1024; Y = 0 }
                "c" = @{ X = 0; Y = 1024 }
                "d" = @{ X = 1024; Y = 1024 }
            }

            foreach ($variant in @("a", "b", "c", "d")) {
                $crop = Copy-Quadrant -Source $master -SourceX $quadrants[$variant].X -SourceY $quadrants[$variant].Y -SourceSize 1024 -OutputSize 512
                try {
                    Save-Png $crop (Join-Path $familyDir ($variant + ".png"))
                    Save-Png $crop (Join-Path $familyDir ($variant + "_atlas.png"))
                }
                finally {
                    $crop.Dispose()
                }

                $blockId = "$($family.Id)_${variant}_block"
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
                        all = "camowarfare:block/$($family.Id)/${variant}_atlas"
                        particle = "camowarfare:block/$($family.Id)/${variant}_atlas"
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
        finally {
            $master.Dispose()
        }
    }

    Save-Png $sheet (Join-Path $previewRoot "nonwoodland_wave1_sheet.png")
}
finally {
    $sheet.Dispose()
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
        $entry = "camowarfare:$($family.Id)_${variant}_block"
        $pickaxeValues.Add($entry) | Out-Null
        $armoredValues.Add($entry) | Out-Null
    }
}

$pickaxeJson.values = @($pickaxeValues | Sort-Object)
Save-Json $pickaxeTagPath $pickaxeJson

$armoredJson.values = @($armoredValues | Sort-Object)
Save-Json $armoredTagPath $armoredJson

Write-Output "non-woodland realistic wave 1 generated"
