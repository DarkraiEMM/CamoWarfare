$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$previewRoot = Join-Path $projectRoot "preview"

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
        }
    }
}

function Save-Png([System.Drawing.Bitmap]$Bitmap, [string]$Path) {
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

Ensure-Directory $previewRoot

$candidates = @(
    @{ Name = "naval_bluegray_reference_1"; Seed = "naval-bluegray-1"; Mode = 1 },
    @{ Name = "naval_bluegray_reference_2"; Seed = "naval-bluegray-2"; Mode = 2 },
    @{ Name = "naval_bluegray_reference_3"; Seed = "naval-bluegray-3"; Mode = 3 }
)

$saved = New-Object System.Collections.Generic.List[string]

foreach ($candidate in $candidates) {
    $bitmap = New-Bitmap 512 512
    try {
        Draw-NavalPattern -Bitmap $bitmap -Seed $candidate.Seed -Mode $candidate.Mode
        $previewPath = Join-Path $previewRoot ($candidate.Name + ".png")
        $rootPath = Join-Path $projectRoot ($candidate.Name + ".png")
        Save-Png -Bitmap $bitmap -Path $previewPath
        Save-Png -Bitmap $bitmap -Path $rootPath
        $saved.Add($previewPath)
    }
    finally {
        $bitmap.Dispose()
    }
}

$sheet = New-Bitmap 1600 620
try {
    Use-Graphics $sheet {
        param($Graphics)
        $Graphics.Clear((ConvertTo-Color "#1A2128"))
        $font = [System.Drawing.Font]::new("Microsoft YaHei UI", 18, [System.Drawing.FontStyle]::Regular)
        $titleFont = [System.Drawing.Font]::new("Microsoft YaHei UI", 22, [System.Drawing.FontStyle]::Bold)
        $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 224, 228, 230))
        try {
            $Graphics.DrawString("Naval Blue-Gray Reference Preview", $titleFont, $textBrush, 24, 18)
            $x = 24
            $index = 1
            foreach ($path in $saved) {
                $image = [System.Drawing.Image]::FromFile($path)
                try {
                    $Graphics.DrawImage($image, $x, 58, 512, 512)
                    $Graphics.DrawString("Option $index", $font, $textBrush, $x, 576)
                }
                finally {
                    $image.Dispose()
                }
                $x += 524
                $index++
            }
        }
        finally {
            $textBrush.Dispose()
            $font.Dispose()
            $titleFont.Dispose()
        }
    }

    $sheetPreview = Join-Path $previewRoot "naval_bluegray_reference_sheet.png"
    $sheetRoot = Join-Path $projectRoot "naval_bluegray_reference_sheet.png"
    Save-Png -Bitmap $sheet -Path $sheetPreview
    Save-Png -Bitmap $sheet -Path $sheetRoot
}
finally {
    $sheet.Dispose()
}
