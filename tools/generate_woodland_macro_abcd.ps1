$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$textureRoot = Join-Path $projectRoot "src\main\resources\assets\camowarfare\textures\block\woodland_macro"

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function New-Bitmap([int]$Width, [int]$Height) {
    return [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
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

function Fill-Polygon([System.Drawing.Graphics]$Graphics, [System.Drawing.Color]$Color, [System.Drawing.PointF[]]$Points) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        $Graphics.FillPolygon($brush, $Points)
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
        $jitterX = 0.72 + ($Random.NextDouble() * 0.45)
        $jitterY = 0.72 + ($Random.NextDouble() * 0.45)
        $x = $CenterX + ([Math]::Cos($angle) * $RadiusX * $jitterX)
        $y = $CenterY + ([Math]::Sin($angle) * $RadiusY * $jitterY)
        $points.Add([System.Drawing.PointF]::new([float]$x, [float]$y))
    }

    return $points.ToArray()
}

function Draw-Master([System.Drawing.Bitmap]$Bitmap) {
    $random = [System.Random]::new(24042426)
    $base = ConvertTo-Color "#59624A"
    $lightOlive = ConvertTo-Color "#73815D"
    $brown = ConvertTo-Color "#705E43"
    $darkOlive = ConvertTo-Color "#303528"
    $accent = ConvertTo-Color "#9AA982"

    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($base)

        foreach ($spec in @(
            @{ Color = $lightOlive; Count = 6; RadiusMin = 34; RadiusMax = 60; AspectMin = 1.1; AspectMax = 1.9 },
            @{ Color = $brown; Count = 5; RadiusMin = 30; RadiusMax = 58; AspectMin = 1.0; AspectMax = 1.8 },
            @{ Color = $darkOlive; Count = 5; RadiusMin = 28; RadiusMax = 54; AspectMin = 1.1; AspectMax = 2.0 },
            @{ Color = $accent; Count = 2; RadiusMin = 18; RadiusMax = 26; AspectMin = 1.0; AspectMax = 1.4 }
        )) {
            for ($i = 0; $i -lt $spec.Count; $i++) {
                $centerX = 16 + ($random.NextDouble() * 222)
                $centerY = 16 + ($random.NextDouble() * 222)
                $radius = $spec.RadiusMin + ($random.NextDouble() * ($spec.RadiusMax - $spec.RadiusMin))
                $aspect = $spec.AspectMin + ($random.NextDouble() * ($spec.AspectMax - $spec.AspectMin))
                if ($random.NextDouble() -gt 0.5) {
                    $radiusX = $radius * $aspect
                    $radiusY = $radius
                }
                else {
                    $radiusX = $radius
                    $radiusY = $radius * $aspect
                }

                $points = New-IrregularPatch `
                    -Random $random `
                    -CenterX $centerX `
                    -CenterY $centerY `
                    -RadiusX $radiusX `
                    -RadiusY $radiusY `
                    -PointCount (8 + $random.Next(5))

                Fill-Polygon -Graphics $Graphics -Color $spec.Color -Points $points
            }
        }
    }
}

function Copy-Rect(
    [System.Drawing.Bitmap]$Source,
    [int]$SourceX,
    [int]$SourceY,
    [int]$Width,
    [int]$Height,
    [System.Drawing.Bitmap]$Target,
    [int]$TargetX,
    [int]$TargetY
) {
    for ($x = 0; $x -lt $Width; $x++) {
        for ($y = 0; $y -lt $Height; $y++) {
            $Target.SetPixel($TargetX + $x, $TargetY + $y, $Source.GetPixel($SourceX + $x, $SourceY + $y))
        }
    }
}

function Get-AverageColor([System.Drawing.Color]$A, [System.Drawing.Color]$B) {
    return [System.Drawing.Color]::FromArgb(
        255,
        [int](($A.R + $B.R) / 2),
        [int](($A.G + $B.G) / 2),
        [int](($A.B + $B.B) / 2)
    )
}

function Build-VerticalBlendStrip(
    [System.Drawing.Bitmap]$Source,
    [int]$LeftX,
    [int]$RightX,
    [int]$SourceY,
    [int]$Height,
    [int]$Border
) {
    $strip = New-Bitmap $Border $Height
    for ($x = 0; $x -lt $Border; $x++) {
        for ($y = 0; $y -lt $Height; $y++) {
            $left = $Source.GetPixel($LeftX, $SourceY + $y)
            $right = $Source.GetPixel($RightX, $SourceY + $y)
            $strip.SetPixel($x, $y, (Get-AverageColor $left $right))
        }
    }
    return $strip
}

function Build-HorizontalBlendStrip(
    [System.Drawing.Bitmap]$Source,
    [int]$SourceX,
    [int]$Width,
    [int]$TopY,
    [int]$BottomY,
    [int]$Border
) {
    $strip = New-Bitmap $Width $Border
    for ($x = 0; $x -lt $Width; $x++) {
        for ($y = 0; $y -lt $Border; $y++) {
            $top = $Source.GetPixel($SourceX + $x, $TopY)
            $bottom = $Source.GetPixel($SourceX + $x, $BottomY)
            $strip.SetPixel($x, $y, (Get-AverageColor $top $bottom))
        }
    }
    return $strip
}

function Build-Corner(
    [System.Drawing.Bitmap]$VerticalStrip,
    [System.Drawing.Bitmap]$HorizontalStrip,
    [int]$Border,
    [bool]$UseVerticalFarSide,
    [bool]$UseHorizontalFarSide
) {
    $corner = New-Bitmap $Border $Border
    for ($x = 0; $x -lt $Border; $x++) {
        for ($y = 0; $y -lt $Border; $y++) {
            $verticalX = if ($UseVerticalFarSide) { $VerticalStrip.Width - $Border + $x } else { $x }
            $horizontalY = if ($UseHorizontalFarSide) { $HorizontalStrip.Height - $Border + $y } else { $y }
            $verticalColor = $VerticalStrip.GetPixel($verticalX, [Math]::Min($VerticalStrip.Height - 1, [int](($VerticalStrip.Height - 1) * (($y + 0.5) / $Border))))
            $horizontalColor = $HorizontalStrip.GetPixel([Math]::Min($HorizontalStrip.Width - 1, [int](($HorizontalStrip.Width - 1) * (($x + 0.5) / $Border))), $horizontalY)
            $corner.SetPixel($x, $y, (Get-AverageColor $verticalColor $horizontalColor))
        }
    }
    return $corner
}

function Build-Tile(
    [System.Drawing.Bitmap]$Master,
    [int]$QuadrantX,
    [int]$QuadrantY,
    [int]$Border,
    [System.Drawing.Bitmap]$LeftStrip,
    [System.Drawing.Bitmap]$RightStrip,
    [System.Drawing.Bitmap]$TopStrip,
    [System.Drawing.Bitmap]$BottomStrip
) {
    if ($Border -eq 0) {
        $tile = New-Bitmap 128 128
        Copy-Rect -Source $Master -SourceX ($QuadrantX * 128) -SourceY ($QuadrantY * 128) -Width 128 -Height 128 -Target $tile -TargetX 0 -TargetY 0
        return $tile
    }

    $tile = New-Bitmap 128 128
    $interior = 128 - ($Border * 2)
    $sourceX = $QuadrantX * $interior
    $sourceY = $QuadrantY * $interior

    Copy-Rect -Source $Master -SourceX $sourceX -SourceY $sourceY -Width $interior -Height $interior -Target $tile -TargetX $Border -TargetY $Border
    Copy-Rect -Source $LeftStrip -SourceX 0 -SourceY 0 -Width $Border -Height $interior -Target $tile -TargetX 0 -TargetY $Border
    Copy-Rect -Source $RightStrip -SourceX 0 -SourceY 0 -Width $Border -Height $interior -Target $tile -TargetX (128 - $Border) -TargetY $Border
    Copy-Rect -Source $TopStrip -SourceX 0 -SourceY 0 -Width $interior -Height $Border -Target $tile -TargetX $Border -TargetY 0
    Copy-Rect -Source $BottomStrip -SourceX 0 -SourceY 0 -Width $interior -Height $Border -Target $tile -TargetX $Border -TargetY (128 - $Border)

    $topLeft = Build-Corner -VerticalStrip $LeftStrip -HorizontalStrip $TopStrip -Border $Border -UseVerticalFarSide:$false -UseHorizontalFarSide:$false
    $topRight = Build-Corner -VerticalStrip $RightStrip -HorizontalStrip $TopStrip -Border $Border -UseVerticalFarSide:$false -UseHorizontalFarSide:$true
    $bottomLeft = Build-Corner -VerticalStrip $LeftStrip -HorizontalStrip $BottomStrip -Border $Border -UseVerticalFarSide:$true -UseHorizontalFarSide:$false
    $bottomRight = Build-Corner -VerticalStrip $RightStrip -HorizontalStrip $BottomStrip -Border $Border -UseVerticalFarSide:$true -UseHorizontalFarSide:$true
    try {
        Copy-Rect -Source $topLeft -SourceX 0 -SourceY 0 -Width $Border -Height $Border -Target $tile -TargetX 0 -TargetY 0
        Copy-Rect -Source $topRight -SourceX 0 -SourceY 0 -Width $Border -Height $Border -Target $tile -TargetX (128 - $Border) -TargetY 0
        Copy-Rect -Source $bottomLeft -SourceX 0 -SourceY 0 -Width $Border -Height $Border -Target $tile -TargetX 0 -TargetY (128 - $Border)
        Copy-Rect -Source $bottomRight -SourceX 0 -SourceY 0 -Width $Border -Height $Border -Target $tile -TargetX (128 - $Border) -TargetY (128 - $Border)
    }
    finally {
        $topLeft.Dispose()
        $topRight.Dispose()
        $bottomLeft.Dispose()
        $bottomRight.Dispose()
    }

    return $tile
}

function Save-Png([System.Drawing.Bitmap]$Bitmap, [string]$Path) {
    if (Test-Path $Path) {
        Remove-Item -LiteralPath $Path -Force
    }
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

Ensure-Directory $textureRoot

$border = 0
$master = New-Bitmap 256 256
$abStrip = $null
$cdStrip = $null
$acStrip = $null
$bdStrip = $null
$selfLeftA = $null
$selfRightB = $null
$selfLeftC = $null
$selfRightD = $null
$selfTopA = $null
$selfTopB = $null
$selfBottomC = $null
$selfBottomD = $null

try {
    Draw-Master -Bitmap $master

    if ($border -gt 0) {
        $abStrip = Build-VerticalBlendStrip -Source $master -LeftX 126 -RightX 127 -SourceY 0 -Height 127 -Border $border
        $cdStrip = Build-VerticalBlendStrip -Source $master -LeftX 126 -RightX 127 -SourceY 127 -Height 127 -Border $border
        $acStrip = Build-HorizontalBlendStrip -Source $master -SourceX 0 -Width 127 -TopY 126 -BottomY 127 -Border $border
        $bdStrip = Build-HorizontalBlendStrip -Source $master -SourceX 127 -Width 127 -TopY 126 -BottomY 127 -Border $border

        $selfLeftA = Build-VerticalBlendStrip -Source $master -LeftX 0 -RightX 126 -SourceY 0 -Height 127 -Border $border
        $selfRightB = Build-VerticalBlendStrip -Source $master -LeftX 127 -RightX 253 -SourceY 0 -Height 127 -Border $border
        $selfLeftC = Build-VerticalBlendStrip -Source $master -LeftX 0 -RightX 126 -SourceY 127 -Height 127 -Border $border
        $selfRightD = Build-VerticalBlendStrip -Source $master -LeftX 127 -RightX 253 -SourceY 127 -Height 127 -Border $border
        $selfTopA = Build-HorizontalBlendStrip -Source $master -SourceX 0 -Width 127 -TopY 0 -BottomY 126 -Border $border
        $selfTopB = Build-HorizontalBlendStrip -Source $master -SourceX 127 -Width 127 -TopY 0 -BottomY 126 -Border $border
        $selfBottomC = Build-HorizontalBlendStrip -Source $master -SourceX 0 -Width 127 -TopY 127 -BottomY 253 -Border $border
        $selfBottomD = Build-HorizontalBlendStrip -Source $master -SourceX 127 -Width 127 -TopY 127 -BottomY 253 -Border $border
    }

    $tiles = @(
        @{ Name = "a"; X = 0; Y = 0; Left = $selfLeftA; Right = $abStrip; Top = $selfTopA; Bottom = $acStrip },
        @{ Name = "b"; X = 1; Y = 0; Left = $abStrip; Right = $selfRightB; Top = $selfTopB; Bottom = $bdStrip },
        @{ Name = "c"; X = 0; Y = 1; Left = $selfLeftC; Right = $cdStrip; Top = $acStrip; Bottom = $selfBottomC },
        @{ Name = "d"; X = 1; Y = 1; Left = $cdStrip; Right = $selfRightD; Top = $bdStrip; Bottom = $selfBottomD }
    )

    foreach ($tileInfo in $tiles) {
        $tile = Build-Tile `
            -Master $master `
            -QuadrantX $tileInfo.X `
            -QuadrantY $tileInfo.Y `
            -Border $border `
            -LeftStrip $tileInfo.Left `
            -RightStrip $tileInfo.Right `
            -TopStrip $tileInfo.Top `
            -BottomStrip $tileInfo.Bottom
        try {
            Save-Png -Bitmap $tile -Path (Join-Path $textureRoot ($tileInfo.Name + "_atlas.png"))
            Save-Png -Bitmap $tile -Path (Join-Path $textureRoot ($tileInfo.Name + ".png"))
        }
        finally {
            $tile.Dispose()
        }
    }
}
finally {
    $master.Dispose()
    if ($abStrip) { $abStrip.Dispose() }
    if ($cdStrip) { $cdStrip.Dispose() }
    if ($acStrip) { $acStrip.Dispose() }
    if ($bdStrip) { $bdStrip.Dispose() }
    if ($selfLeftA) { $selfLeftA.Dispose() }
    if ($selfRightB) { $selfRightB.Dispose() }
    if ($selfLeftC) { $selfLeftC.Dispose() }
    if ($selfRightD) { $selfRightD.Dispose() }
    if ($selfTopA) { $selfTopA.Dispose() }
    if ($selfTopB) { $selfTopB.Dispose() }
    if ($selfBottomC) { $selfBottomC.Dispose() }
    if ($selfBottomD) { $selfBottomD.Dispose() }
}
