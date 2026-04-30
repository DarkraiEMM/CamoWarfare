$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$targetRoot = Join-Path $projectRoot "src\main\resources\assets\camowarfare\textures\block\naval_bluegray"

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
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

function ConvertTo-Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
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
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
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
        $jitterX = 0.76 + ($Random.NextDouble() * 0.42)
        $jitterY = 0.76 + ($Random.NextDouble() * 0.42)
        $x = $CenterX + ([Math]::Cos($angle) * $RadiusX * $jitterX)
        $y = $CenterY + ([Math]::Sin($angle) * $RadiusY * $jitterY)
        $points.Add([System.Drawing.PointF]::new([float]$x, [float]$y))
    }

    return $points.ToArray()
}

function Add-PatchLayer(
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

        $points = New-IrregularPatch `
            -Random $Random `
            -CenterX $centerX `
            -CenterY $centerY `
            -RadiusX $radiusX `
            -RadiusY $radiusY `
            -PointCount (8 + $Random.Next(5))

        Fill-WrappedPolygon -Graphics $Graphics -Color $Color -Points $points -TileSize $TileSize
    }
}

function Draw-NavalPattern([System.Drawing.Bitmap]$Bitmap, [string]$Seed, [int]$Mode) {
    $random = [System.Random]::new([Math]::Abs($Seed.GetHashCode()))
    $tileSize = $Bitmap.Width

    $base = ConvertTo-Color "#526272"
    $light = ConvertTo-Color "#73879A"
    $mid = ConvertTo-Color "#66798B"
    $dark = ConvertTo-Color "#32414E"
    $deep = ConvertTo-Color "#1F2A34"

    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($base)

        switch ($Mode) {
            1 {
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $light -TileSize $tileSize -Count 4 -RadiusMin 62 -RadiusMax 92 -AspectMin 1.2 -AspectMax 1.9
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $dark -TileSize $tileSize -Count 4 -RadiusMin 58 -RadiusMax 86 -AspectMin 1.1 -AspectMax 1.8
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $mid -TileSize $tileSize -Count 2 -RadiusMin 48 -RadiusMax 76 -AspectMin 1.1 -AspectMax 1.6
            }
            2 {
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $light -TileSize $tileSize -Count 3 -RadiusMin 72 -RadiusMax 108 -AspectMin 1.5 -AspectMax 2.4
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $dark -TileSize $tileSize -Count 3 -RadiusMin 66 -RadiusMax 102 -AspectMin 1.4 -AspectMax 2.2
                for ($i = 0; $i -lt 4; $i++) {
                    $x = 40 + $random.Next(360)
                    $y = 60 + $random.Next(320)
                    $w = 90 + $random.Next(120)
                    $h = 14 + $random.Next(18)
                    Fill-WrappedRect -Graphics $Graphics -Color $mid -X $x -Y $y -Width $w -Height $h -TileSize $tileSize
                }
            }
            3 {
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $light -TileSize $tileSize -Count 4 -RadiusMin 58 -RadiusMax 90 -AspectMin 1.3 -AspectMax 2.0
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $dark -TileSize $tileSize -Count 4 -RadiusMin 54 -RadiusMax 86 -AspectMin 1.3 -AspectMax 2.0
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $deep -TileSize $tileSize -Count 2 -RadiusMin 44 -RadiusMax 66 -AspectMin 1.1 -AspectMax 1.6
                for ($i = 0; $i -lt 5; $i++) {
                    $x1 = $random.NextDouble() * $tileSize
                    $y1 = $random.NextDouble() * $tileSize
                    $x2 = $x1 + 80 + $random.Next(120)
                    $y2 = $y1 + (-40 + $random.Next(80))
                    Draw-WrappedLine -Graphics $Graphics -Color $mid -X1 $x1 -Y1 $y1 -X2 $x2 -Y2 $y2 -Width 6 -TileSize $tileSize
                }
            }
            4 {
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $light -TileSize $tileSize -Count 4 -RadiusMin 64 -RadiusMax 96 -AspectMin 1.3 -AspectMax 2.1
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $dark -TileSize $tileSize -Count 4 -RadiusMin 60 -RadiusMax 92 -AspectMin 1.2 -AspectMax 1.9
                Add-PatchLayer -Graphics $Graphics -Random $random -Color $mid -TileSize $tileSize -Count 3 -RadiusMin 48 -RadiusMax 70 -AspectMin 1.1 -AspectMax 1.7
                for ($i = 0; $i -lt 3; $i++) {
                    $x = 70 + $random.Next(300)
                    $y = 70 + $random.Next(300)
                    $w = 120 + $random.Next(90)
                    $h = 10 + $random.Next(14)
                    Fill-WrappedRect -Graphics $Graphics -Color $deep -X $x -Y $y -Width $w -Height $h -TileSize $tileSize
                }
            }
        }
    }
}

function Save-Png([System.Drawing.Bitmap]$Bitmap, [string]$Path) {
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Resize-To128([System.Drawing.Image]$Image) {
    $bitmap = New-Bitmap 128 128
    Use-Graphics $bitmap {
        param($Graphics)
        $Graphics.DrawImage($Image, 0, 0, 128, 128)
    }
    return $bitmap
}

Ensure-Directory $targetRoot

$variants = @(
    @{ Name = "a"; Source = (Join-Path $projectRoot "naval_bluegray_reference_1.png"); Mode = 0; Seed = "" },
    @{ Name = "b"; Source = (Join-Path $projectRoot "naval_bluegray_reference_2.png"); Mode = 0; Seed = "" },
    @{ Name = "c"; Source = (Join-Path $projectRoot "naval_bluegray_reference_3.png"); Mode = 0; Seed = "" },
    @{ Name = "d"; Source = $null; Mode = 4; Seed = "naval-bluegray-4" }
)

foreach ($variant in $variants) {
    if ($variant.Source) {
        $image = [System.Drawing.Image]::FromFile($variant.Source)
        try {
            $sample = Resize-To128 $image
        }
        finally {
            $image.Dispose()
        }
    }
    else {
        $sample = New-Bitmap 128 128
        Draw-NavalPattern -Bitmap $sample -Seed $variant.Seed -Mode $variant.Mode
    }

    try {
        $samplePath = Join-Path $targetRoot ($variant.Name + "_atlas.png")
        $atlasPath = Join-Path $targetRoot ($variant.Name + ".png")
        Save-Png -Bitmap $sample -Path $samplePath
        Save-Png -Bitmap $sample -Path $atlasPath
    }
    finally {
        $sample.Dispose()
    }
}

Write-Output "naval bluegray family refreshed"
