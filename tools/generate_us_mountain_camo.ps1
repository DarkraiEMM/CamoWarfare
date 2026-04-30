$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$textureRoot = Join-Path $projectRoot "src\main\resources\assets\camowarfare\textures\block"
$previewDir = Join-Path $projectRoot "preview"
$sourceDir = Join-Path $projectRoot "source"

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function New-Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function New-Alpha([System.Drawing.Color]$Color, [int]$Alpha) {
    return [System.Drawing.Color]::FromArgb($Alpha, $Color.R, $Color.G, $Color.B)
}

function Mix-Color([System.Drawing.Color]$A, [System.Drawing.Color]$B, [double]$WeightB) {
    $weightA = 1.0 - $WeightB
    return [System.Drawing.Color]::FromArgb(
        255,
        [int][Math]::Round(($A.R * $weightA) + ($B.R * $WeightB)),
        [int][Math]::Round(($A.G * $weightA) + ($B.G * $WeightB)),
        [int][Math]::Round(($A.B * $weightA) + ($B.B * $WeightB))
    )
}

function Fill-Rect($Graphics, [System.Drawing.Color]$Color, [int]$X, [int]$Y, [int]$Width, [int]$Height) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        $Graphics.FillRectangle($brush, $X, $Y, $Width, $Height)
    }
    finally {
        $brush.Dispose()
    }
}

function Fill-ClosedCurve($Graphics, [System.Drawing.Color]$Color, [float[][]]$Points, [float]$Tension) {
    $pointArray = New-Object System.Drawing.PointF[] $Points.Count
    for ($i = 0; $i -lt $Points.Count; $i++) {
        $pointArray[$i] = [System.Drawing.PointF]::new([float]$Points[$i][0], [float]$Points[$i][1])
    }
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        $Graphics.FillClosedCurve($brush, $pointArray, [System.Drawing.Drawing2D.FillMode]::Winding, $Tension)
    }
    finally {
        $brush.Dispose()
    }
}

function Draw-CurveBand($Graphics, [System.Drawing.Color]$Color, [float[][]]$Points, [float]$Width, [float]$Tension) {
    $pointArray = New-Object System.Drawing.PointF[] $Points.Count
    for ($i = 0; $i -lt $Points.Count; $i++) {
        $pointArray[$i] = [System.Drawing.PointF]::new([float]$Points[$i][0], [float]$Points[$i][1])
    }
    $pen = [System.Drawing.Pen]::new($Color, $Width)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    try {
        $Graphics.DrawCurve($pen, $pointArray, $Tension)
    }
    finally {
        $pen.Dispose()
    }
}

function Draw-WrappedCurveBand($Graphics, [System.Drawing.Color]$Color, [float[][]]$Points, [float]$Width, [float]$Tension) {
    foreach ($offsetX in @(-512, 0, 512)) {
        foreach ($offsetY in @(-512, 0, 512)) {
            $shifted = @()
            foreach ($point in $Points) {
                $shifted += ,@([float]($point[0] + $offsetX), [float]($point[1] + $offsetY))
            }
            Draw-CurveBand $Graphics $Color $shifted $Width $Tension
        }
    }
}

function Fill-WrappedClosedCurve($Graphics, [System.Drawing.Color]$Color, [float[][]]$Points, [float]$Tension) {
    foreach ($offsetX in @(-512, 0, 512)) {
        foreach ($offsetY in @(-512, 0, 512)) {
            $shifted = @()
            foreach ($point in $Points) {
                $shifted += ,@([float]($point[0] + $offsetX), [float]($point[1] + $offsetY))
            }
            Fill-ClosedCurve $Graphics $Color $shifted $Tension
        }
    }
}

function New-OrganicBlob([float]$CenterX, [float]$CenterY, [float]$RadiusX, [float]$RadiusY, [double]$SeedPhase, [int]$Points) {
    $result = @()
    for ($i = 0; $i -lt $Points; $i++) {
        $angle = (2.0 * [Math]::PI * $i) / $Points
        $wave = 1.0 + (0.17 * [Math]::Sin(($angle * 3.0) + $SeedPhase)) + (0.10 * [Math]::Sin(($angle * 7.0) + ($SeedPhase * 1.7)))
        $result += ,@(
            [float]($CenterX + ([Math]::Cos($angle) * $RadiusX * $wave)),
            [float]($CenterY + ([Math]::Sin($angle) * $RadiusY * $wave))
        )
    }
    return $result
}

function Add-WrappedBlob($Graphics, [System.Drawing.Color]$Color, [float]$CenterX, [float]$CenterY, [float]$RadiusX, [float]$RadiusY, [double]$SeedPhase) {
    Fill-WrappedClosedCurve $Graphics $Color (New-OrganicBlob $CenterX $CenterY $RadiusX $RadiusY $SeedPhase 28) 0.36
}

function New-RotatedOrganicBlob([float]$CenterX, [float]$CenterY, [float]$RadiusX, [float]$RadiusY, [double]$Angle, [double]$SeedPhase, [int]$Points) {
    $result = @()
    $cos = [Math]::Cos($Angle)
    $sin = [Math]::Sin($Angle)
    for ($i = 0; $i -lt $Points; $i++) {
        $t = (2.0 * [Math]::PI * $i) / $Points
        $wave = 1.0 + (0.22 * [Math]::Sin(($t * 3.0) + $SeedPhase)) + (0.13 * [Math]::Sin(($t * 5.0) + ($SeedPhase * 1.9)))
        $x = [Math]::Cos($t) * $RadiusX * $wave
        $y = [Math]::Sin($t) * $RadiusY * $wave
        $result += ,@(
            [float]($CenterX + ($x * $cos) - ($y * $sin)),
            [float]($CenterY + ($x * $sin) + ($y * $cos))
        )
    }
    return $result
}

function Add-WrappedRotatedBlob($Graphics, [System.Drawing.Color]$Color, [float]$CenterX, [float]$CenterY, [float]$RadiusX, [float]$RadiusY, [double]$Angle, [double]$SeedPhase) {
    Fill-WrappedClosedCurve $Graphics $Color (New-RotatedOrganicBlob $CenterX $CenterY $RadiusX $RadiusY $Angle $SeedPhase 30) 0.38
}

function Add-PaintNoise([System.Drawing.Bitmap]$Bitmap, [int]$Seed, [int]$Count, [int]$DarkAlpha, [int]$LightAlpha) {
    $graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $random = [System.Random]::new($Seed)
    try {
        for ($i = 0; $i -lt $Count; $i++) {
            $x = $random.Next(0, 512)
            $y = $random.Next(0, 512)
            $size = 1 + $random.Next(0, 2)
            if ($random.NextDouble() -lt 0.72) {
                $color = [System.Drawing.Color]::FromArgb($DarkAlpha, 13, 14, 11)
            }
            else {
                $color = [System.Drawing.Color]::FromArgb($LightAlpha, 178, 169, 139)
            }
            Fill-Rect $graphics $color $x $y $size $size
        }
    }
    finally {
        $graphics.Dispose()
    }
}

function Add-SoftEdgeSpeckles([System.Drawing.Bitmap]$Bitmap, [int]$Seed, [System.Drawing.Color]$Tone) {
    $graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $random = [System.Random]::new($Seed)
    try {
        for ($i = 0; $i -lt 180; $i++) {
            $x = $random.Next(-20, 500)
            $y = $random.Next(-20, 500)
            $w = 18 + $random.Next(0, 44)
            $h = 4 + $random.Next(0, 12)
            $color = New-Alpha $Tone (16 + $random.Next(0, 22))
            Fill-Rect $graphics $color $x $y $w $h
        }
    }
    finally {
        $graphics.Dispose()
    }
}

function Save-CamoSet([string]$Name, [System.Drawing.Bitmap]$Bitmap) {
    $dir = Join-Path $textureRoot $Name
    Ensure-Directory $dir
    $Bitmap.Save((Join-Path $dir "variant_0.png"), [System.Drawing.Imaging.ImageFormat]::Png)

    $item = $Bitmap.Clone([System.Drawing.Rectangle]::new(64, 64, 256, 256), $Bitmap.PixelFormat)
    try {
        $item.Save((Join-Path $dir "variant_1.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $item.Dispose()
    }
}

function Import-CamoSetFromImage([string]$Name, [string]$SourcePath) {
    $source = [System.Drawing.Image]::FromFile($SourcePath)
    try {
        $side = [Math]::Min($source.Width, $source.Height)
        $sourceRect = [System.Drawing.Rectangle]::new(
            [int](($source.Width - $side) / 2),
            [int](($source.Height - $side) / 2),
            $side,
            $side
        )
        $cropped = [System.Drawing.Bitmap]::new($side, $side, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $cropGraphics = [System.Drawing.Graphics]::FromImage($cropped)
        $cropGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $cropGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        try {
            $cropGraphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, $side, $side), $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
        }
        finally {
            $cropGraphics.Dispose()
        }

        $bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        try {
            $graphics.DrawImage($cropped, 0, 0, 512, 512)
        }
        finally {
            $graphics.Dispose()
            $cropped.Dispose()
        }
        return $bitmap
    }
    finally {
        $source.Dispose()
    }
}

function Find-SourceImage([string]$BaseName) {
    foreach ($extension in @(".png", ".jpg", ".jpeg")) {
        $path = Join-Path $sourceDir ($BaseName + $extension)
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

function New-NatoTricolorMountain {
    $base = New-Color "#4F5843"
    $oliveDark = New-Color "#313B2E"
    $brown = New-Color "#66473A"
    $black = New-Color "#202524"
    $khaki = New-Color "#B09D7E"
    $shade = New-Color "#171A16"

    $bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    try {
        $graphics.Clear($base)

        # Tileable NATO woodland-style vehicle coating: organic islands that wrap over atlas borders.
        Add-WrappedBlob $graphics $oliveDark 50 80 128 74 0.4
        Add-WrappedBlob $graphics $oliveDark 210 372 150 92 1.2
        Add-WrappedBlob $graphics $oliveDark 466 238 128 84 2.0

        Add-WrappedBlob $graphics $brown 152 48 98 58 2.5
        Add-WrappedBlob $graphics $brown 332 156 112 72 0.9
        Add-WrappedBlob $graphics $brown 88 430 116 68 1.8
        Add-WrappedBlob $graphics $brown 500 22 92 52 2.8

        Add-WrappedBlob $graphics $black 56 245 130 44 0.7
        Add-WrappedBlob $graphics $black 256 250 138 56 1.5
        Add-WrappedBlob $graphics $black 426 424 150 54 2.4
        Add-WrappedBlob $graphics $black 486 84 92 38 3.1

        Add-WrappedBlob $graphics $khaki 124 198 72 38 1.0
        Add-WrappedBlob $graphics $khaki 340 326 82 42 2.2
        Add-WrappedBlob $graphics $khaki 468 172 62 32 0.2
        Add-WrappedBlob $graphics $khaki 22 492 74 34 2.9

        Fill-WrappedClosedCurve $graphics (New-Alpha $shade 72) @(
            @(0, 330), @(92, 306), @(178, 338), @(236, 392), @(330, 382), @(426, 430),
            @(516, 404), @(516, 468), @(424, 490), @(316, 454), @(218, 470), @(118, 424), @(0, 452)
        ) 0.45

        Add-SoftEdgeSpeckles $bitmap 92011 $shade
    }
    finally {
        $graphics.Dispose()
    }

    Add-PaintNoise $bitmap 31017 3400 42 24
    return $bitmap
}

function New-MerdcGrayMountain {
    $baseGreen = New-Color "#2F3B25"
    $darkGreen = New-Color "#27331F"
    $brown = New-Color "#84613C"
    $sandRibbon = New-Color "#CDBD91"
    $black = New-Color "#060705"

    $bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    try {
        $graphics.Clear($baseGreen)

        # Trace from the supplied material: dense organic woodland blobs, tan ribbons, black twig marks.
        Add-WrappedBlob $graphics $brown 22 36 70 44 0.2
        Add-WrappedBlob $graphics $brown 168 30 76 50 1.1
        Add-WrappedBlob $graphics $brown 338 58 82 48 2.0
        Add-WrappedBlob $graphics $brown 486 36 74 46 2.9
        Add-WrappedBlob $graphics $brown 88 154 84 52 3.5
        Add-WrappedBlob $graphics $brown 264 168 96 58 1.8
        Add-WrappedBlob $graphics $brown 444 174 82 52 0.7
        Add-WrappedBlob $graphics $brown 26 276 86 54 2.4
        Add-WrappedBlob $graphics $brown 190 294 94 58 3.2
        Add-WrappedBlob $graphics $brown 386 286 92 56 1.4
        Add-WrappedBlob $graphics $brown 116 426 100 60 0.9
        Add-WrappedBlob $graphics $brown 318 438 104 64 2.6
        Add-WrappedBlob $graphics $brown 514 430 76 48 3.7

        Add-WrappedBlob $graphics $darkGreen 104 70 66 44 2.2
        Add-WrappedBlob $graphics $darkGreen 246 54 78 48 0.8
        Add-WrappedBlob $graphics $darkGreen 414 104 74 46 1.5
        Add-WrappedBlob $graphics $darkGreen 150 224 88 54 2.9
        Add-WrappedBlob $graphics $darkGreen 338 244 84 52 3.8
        Add-WrappedBlob $graphics $darkGreen 62 386 80 48 1.9
        Add-WrappedBlob $graphics $darkGreen 260 390 92 56 0.4
        Add-WrappedBlob $graphics $darkGreen 456 380 74 48 2.7

        # Tan and black are irregular fragments embedded between color fields, not strokes.
        Fill-WrappedClosedCurve $graphics $sandRibbon @(@(-8,118),@(24,108),@(48,118),@(76,106),@(104,114),@(86,136),@(52,140),@(24,132)) 0.42
        Fill-WrappedClosedCurve $graphics $sandRibbon @(@(176,18),@(210,28),@(236,18),@(268,30),@(248,48),@(206,50),@(186,40)) 0.42
        Fill-WrappedClosedCurve $graphics $sandRibbon @(@(326,158),@(356,170),@(386,160),@(420,176),@(398,198),@(358,194),@(334,184)) 0.42
        Fill-WrappedClosedCurve $graphics $sandRibbon @(@(442,198),@(474,190),@(506,202),@(536,194),@(520,220),@(482,222),@(450,214)) 0.42
        Fill-WrappedClosedCurve $graphics $sandRibbon @(@(2,340),@(36,326),@(70,338),@(104,326),@(124,346),@(92,366),@(48,360),@(18,354)) 0.42
        Fill-WrappedClosedCurve $graphics $sandRibbon @(@(238,326),@(272,342),@(306,330),@(340,342),@(320,364),@(278,362),@(246,350)) 0.42
        Fill-WrappedClosedCurve $graphics $sandRibbon @(@(370,496),@(404,476),@(442,486),@(480,472),@(464,504),@(422,506),@(390,512)) 0.42
        Fill-WrappedClosedCurve $graphics $sandRibbon @(@(128,128),@(154,120),@(184,130),@(204,118),@(196,142),@(162,150),@(136,144)) 0.42

        Fill-WrappedClosedCurve $graphics $black @(@(42,42),@(58,48),@(74,60),@(92,56),@(110,66),@(98,82),@(76,72),@(56,76),@(42,64)) 0.34
        Fill-WrappedClosedCurve $graphics $black @(@(204,112),@(224,120),@(242,112),@(262,126),@(284,124),@(268,146),@(244,140),@(224,150),@(210,134)) 0.34
        Fill-WrappedClosedCurve $graphics $black @(@(396,36),@(416,48),@(436,42),@(458,54),@(480,50),@(464,72),@(438,64),@(416,74),@(402,58)) 0.34
        Fill-WrappedClosedCurve $graphics $black @(@(18,214),@(38,222),@(56,214),@(78,228),@(100,226),@(84,248),@(58,240),@(36,252),@(22,234)) 0.34
        Fill-WrappedClosedCurve $graphics $black @(@(326,222),@(348,232),@(368,224),@(390,238),@(414,236),@(396,260),@(370,250),@(346,262),@(332,242)) 0.34
        Fill-WrappedClosedCurve $graphics $black @(@(144,350),@(164,360),@(184,354),@(206,368),@(230,366),@(212,390),@(184,380),@(164,392),@(150,372)) 0.34
        Fill-WrappedClosedCurve $graphics $black @(@(452,318),@(472,330),@(492,322),@(516,338),@(536,336),@(520,358),@(494,350),@(470,360),@(456,340)) 0.34
        Fill-WrappedClosedCurve $graphics $black @(@(286,474),@(308,484),@(330,476),@(352,492),@(376,488),@(358,512),@(330,502),@(306,512),@(292,494)) 0.34

        Add-SoftEdgeSpeckles $bitmap 93021 (New-Color "#1A2216")
    }
    finally {
        $graphics.Dispose()
    }

    Add-PaintNoise $bitmap 42029 2200 24 12
    return $bitmap
}

function New-EdrlGreen {
    $base = New-Color "#5A5A45"
    $lightGreen = New-Color "#7E9363"
    $midGreen = New-Color "#456546"
    $darkGreen = New-Color "#344F38"
    $brown = New-Color "#666049"
    $black = New-Color "#283133"

    $bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    try {
        $graphics.Clear($base)

        # EDRL green: dense leaf-like fragments, drawn as wrapped blobs so adjacent blocks still connect.
        $random = [System.Random]::new(76021)
        foreach ($layer in @(
            @{ Color = $brown; Count = 22; MinX = 58; MaxX = 126; MinY = 18; MaxY = 36 },
            @{ Color = $midGreen; Count = 28; MinX = 54; MaxX = 118; MinY = 20; MaxY = 42 },
            @{ Color = $darkGreen; Count = 20; MinX = 48; MaxX = 96; MinY = 16; MaxY = 34 },
            @{ Color = $lightGreen; Count = 24; MinX = 36; MaxX = 86; MinY = 12; MaxY = 28 }
        )) {
            for ($i = 0; $i -lt $layer.Count; $i++) {
                $cx = [float]$random.Next(0, 512)
                $cy = [float]$random.Next(0, 512)
                $rx = [float]($layer.MinX + $random.NextDouble() * ($layer.MaxX - $layer.MinX))
                $ry = [float]($layer.MinY + $random.NextDouble() * ($layer.MaxY - $layer.MinY))
                $angle = ($random.NextDouble() * [Math]::PI) - ([Math]::PI / 2.0)
                Add-WrappedRotatedBlob $graphics $layer.Color $cx $cy $rx $ry $angle ($random.NextDouble() * 10.0)
            }
        }

        for ($i = 0; $i -lt 30; $i++) {
            $cx = [float]$random.Next(0, 512)
            $cy = [float]$random.Next(0, 512)
            $rx = [float](20 + $random.NextDouble() * 58)
            $ry = [float](5 + $random.NextDouble() * 14)
            $angle = ($random.NextDouble() * [Math]::PI) - ([Math]::PI / 2.0)
            Add-WrappedRotatedBlob $graphics $black $cx $cy $rx $ry $angle ($random.NextDouble() * 10.0)
        }

        Add-SoftEdgeSpeckles $bitmap 95031 (New-Color "#20281F")
    }
    finally {
        $graphics.Dispose()
    }

    Add-PaintNoise $bitmap 95177 2600 22 10
    return $bitmap
}

function Add-DigitalScatter($Graphics, [System.Random]$Random, [System.Drawing.Color]$Color, [int]$Count, [int]$MaxWidthCells, [int]$MaxHeightCells, [int]$CellSize) {
    for ($i = 0; $i -lt $Count; $i++) {
        $x = $Random.Next(0, [int](512 / $CellSize)) * $CellSize
        $y = $Random.Next(0, [int](512 / $CellSize)) * $CellSize
        $w = (1 + $Random.Next(0, $MaxWidthCells)) * $CellSize
        $h = (1 + $Random.Next(0, $MaxHeightCells)) * $CellSize
        Fill-Rect $Graphics $Color $x $y $w $h
    }
}

function New-RussianEmr {
    $base = New-Color "#7A7D59"
    $light = New-Color "#90946A"
    $green = New-Color "#4B5C3E"
    $deepGreen = New-Color "#394735"
    $brown = New-Color "#5E4B3A"
    $black = New-Color "#282D31"

    $smooth = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($smooth)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    try {
        $graphics.Clear($base)

        foreach ($blob in @(
            @($green, 58, 44, 116, 84, -0.4, 1.1), @($green, 190, 86, 132, 92, 0.2, 2.0),
            @($green, 372, 70, 118, 86, -0.2, 3.1), @($green, 92, 232, 142, 94, 0.4, 4.0),
            @($green, 302, 230, 146, 98, -0.3, 5.2), @($green, 472, 286, 112, 84, 0.1, 6.1),
            @($green, 170, 418, 148, 96, -0.1, 7.0), @($green, 406, 438, 130, 90, 0.3, 8.4),
            @($light, 42, 156, 80, 50, 0.1, 1.6), @($light, 250, 28, 90, 52, -0.1, 2.8),
            @($light, 446, 156, 86, 54, 0.5, 3.3), @($light, 198, 318, 100, 58, -0.4, 4.9),
            @($light, 352, 360, 92, 56, 0.2, 6.4), @($light, 68, 470, 82, 48, -0.2, 7.7),
            @($deepGreen, 146, 142, 86, 54, -0.5, 1.9), @($deepGreen, 332, 138, 92, 58, 0.4, 2.7),
            @($deepGreen, 32, 348, 96, 62, 0.1, 4.1), @($deepGreen, 438, 20, 82, 52, -0.3, 5.8),
            @($brown, 112, 78, 58, 34, 0.2, 2.3), @($brown, 282, 166, 66, 36, -0.4, 3.9),
            @($brown, 104, 362, 70, 38, 0.3, 5.1), @($brown, 410, 316, 74, 40, -0.2, 6.8)
        )) {
            Add-WrappedRotatedBlob $graphics $blob[0] $blob[1] $blob[2] $blob[3] $blob[4] $blob[5] $blob[6]
        }

        foreach ($blob in @(
            @($black, 238, 118, 58, 18, -0.6, 1.2), @($black, 392, 84, 70, 20, 0.3, 2.4),
            @($black, 82, 286, 72, 18, 0.5, 3.7), @($black, 270, 286, 66, 18, -0.4, 4.9),
            @($black, 434, 470, 64, 18, 0.2, 5.8), @($black, 18, 42, 54, 16, -0.2, 6.6)
        )) {
            Add-WrappedRotatedBlob $graphics $blob[0] $blob[1] $blob[2] $blob[3] $blob[4] $blob[5] $blob[6]
        }
    }
    finally {
        $graphics.Dispose()
    }

    $small = [System.Drawing.Bitmap]::new(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $smallGraphics = [System.Drawing.Graphics]::FromImage($small)
    $smallGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $smallGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    try {
        $smallGraphics.DrawImage($smooth, 0, 0, 256, 256)
    }
    finally {
        $smallGraphics.Dispose()
        $smooth.Dispose()
    }

    $bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    try {
        $graphics.DrawImage($small, 0, 0, 512, 512)
        $random = [System.Random]::new(88043)
        Add-DigitalScatter $graphics $random $green 1900 3 2 2
        Add-DigitalScatter $graphics $random $deepGreen 1350 3 2 2
        Add-DigitalScatter $graphics $random $light 950 3 2 2
        Add-DigitalScatter $graphics $random $brown 700 2 2 2
        Add-DigitalScatter $graphics $random $black 520 2 2 2
        Add-DigitalScatter $graphics $random (Mix-Color $base $black 0.22) 900 2 1 2
    }
    finally {
        $graphics.Dispose()
        $small.Dispose()
    }

    return $bitmap
}

function Add-MulticamShadowFragments($Graphics, [System.Random]$Random, [System.Drawing.Color]$Color, [int]$Count) {
    for ($i = 0; $i -lt $Count; $i++) {
        $cx = [float]$Random.Next(0, 512)
        $cy = [float]$Random.Next(0, 512)
        $rx = [float](12 + $Random.NextDouble() * 34)
        $ry = [float](4 + $Random.NextDouble() * 12)
        $angle = ($Random.NextDouble() * [Math]::PI) - ([Math]::PI / 2.0)
        Add-WrappedRotatedBlob $Graphics $Color $cx $cy $rx $ry $angle ($Random.NextDouble() * 10.0)
    }
}

function New-UsOcpMulticam {
    $base = New-Color "#B7A77C"
    $paleSand = New-Color "#D2C49C"
    $fieldTan = New-Color "#9F916F"
    $olive = New-Color "#6F7653"
    $deepOlive = New-Color "#4D573D"
    $brown = New-Color "#7B5F43"
    $dark = New-Color "#3B3A2E"

    $bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    try {
        $graphics.Clear($base)

        # Vehicle-scaled OCP/MultiCam: broader fields first, then small broken shadows.
        Add-WrappedRotatedBlob $graphics $fieldTan 44 86 134 62 -0.20 1.1
        Add-WrappedRotatedBlob $graphics $fieldTan 292 78 150 66 0.12 2.4
        Add-WrappedRotatedBlob $graphics $fieldTan 116 316 164 70 0.18 3.6
        Add-WrappedRotatedBlob $graphics $fieldTan 432 338 146 62 -0.28 4.8

        Add-WrappedRotatedBlob $graphics $olive 156 158 118 54 -0.42 5.1
        Add-WrappedRotatedBlob $graphics $olive 370 188 132 60 0.34 6.3
        Add-WrappedRotatedBlob $graphics $olive 58 438 124 56 0.22 7.0
        Add-WrappedRotatedBlob $graphics $olive 276 430 140 58 -0.18 8.2

        Add-WrappedRotatedBlob $graphics $deepOlive 34 230 96 40 0.32 2.1
        Add-WrappedRotatedBlob $graphics $deepOlive 238 262 114 46 -0.25 3.2
        Add-WrappedRotatedBlob $graphics $deepOlive 480 66 86 38 0.22 4.4
        Add-WrappedRotatedBlob $graphics $deepOlive 474 462 102 42 -0.34 5.7

        Add-WrappedRotatedBlob $graphics $brown 90 34 86 36 0.28 3.8
        Add-WrappedRotatedBlob $graphics $brown 338 18 102 42 -0.20 4.5
        Add-WrappedRotatedBlob $graphics $brown 196 372 96 40 0.16 5.9
        Add-WrappedRotatedBlob $graphics $brown 416 254 90 36 -0.34 6.8

        Add-WrappedRotatedBlob $graphics $paleSand 210 58 92 30 -0.12 0.8
        Add-WrappedRotatedBlob $graphics $paleSand 36 356 86 30 0.30 1.7
        Add-WrappedRotatedBlob $graphics $paleSand 334 324 110 34 -0.25 2.9
        Add-WrappedRotatedBlob $graphics $paleSand 486 158 78 28 0.22 4.1

        $random = [System.Random]::new(77103)
        Add-MulticamShadowFragments $graphics $random $dark 34
        Add-MulticamShadowFragments $graphics $random (Mix-Color $brown $dark 0.35) 24
        Add-MulticamShadowFragments $graphics $random (Mix-Color $paleSand $base 0.25) 18
        Add-SoftEdgeSpeckles $bitmap 77113 (New-Color "#5C513A")
    }
    finally {
        $graphics.Dispose()
    }

    Add-PaintNoise $bitmap 77129 2500 24 16
    return $bitmap
}

function New-CarcIndustrialCoating([string]$BaseHex, [string]$Name, [int]$Seed) {
    $base = New-Color $BaseHex
    $dark = Mix-Color $base (New-Color "#111111") 0.26
    $deep = Mix-Color $base (New-Color "#050505") 0.42
    $light = Mix-Color $base (New-Color "#FFFFFF") 0.14
    $scuff = Mix-Color $base (New-Color "#C9C0A2") 0.10

    $bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $random = [System.Random]::new($Seed)
    try {
        $graphics.Clear($base)

        for ($y = 8; $y -lt 512; $y += 18 + $random.Next(0, 18)) {
            $alpha = 16 + $random.Next(0, 16)
            $tone = if ($random.NextDouble() -lt 0.55) { New-Alpha $dark $alpha } else { New-Alpha $light $alpha }
            Fill-Rect $graphics $tone 0 $y 512 (2 + $random.Next(0, 3))
        }

        for ($i = 0; $i -lt 86; $i++) {
            $x = $random.Next(0, 32) * 16
            $y = $random.Next(0, 32) * 16
            $w = (1 + $random.Next(1, 5)) * 16
            $h = (1 + $random.Next(0, 3)) * 12
            $tone = if ($random.NextDouble() -lt 0.62) { New-Alpha $dark (20 + $random.Next(0, 34)) } else { New-Alpha $light (14 + $random.Next(0, 22)) }
            Fill-Rect $graphics $tone $x $y $w $h
        }

        for ($i = 0; $i -lt 220; $i++) {
            $x = $random.Next(0, 512)
            $y = $random.Next(0, 512)
            $w = 4 + $random.Next(0, 22)
            $h = 1 + $random.Next(0, 3)
            Fill-Rect $graphics (New-Alpha $scuff (16 + $random.Next(0, 24))) $x $y $w $h
        }

        Fill-Rect $graphics (New-Alpha $deep 44) 0 0 512 10
        Fill-Rect $graphics (New-Alpha $deep 54) 0 502 512 10
        Fill-Rect $graphics (New-Alpha $deep 42) 0 0 10 512
        Fill-Rect $graphics (New-Alpha $deep 52) 502 0 10 512
        Fill-Rect $graphics (New-Alpha $light 28) 16 16 480 3
        Fill-Rect $graphics (New-Alpha $light 18) 16 16 3 480
    }
    finally {
        $graphics.Dispose()
    }

    Add-PaintNoise $bitmap ($Seed + 17) 1800 18 10
    return $bitmap
}

Ensure-Directory $textureRoot
Ensure-Directory $previewDir
Ensure-Directory $sourceDir

$nato = New-NatoTricolorMountain
$merdc = New-MerdcGrayMountain
$edrl = New-EdrlGreen
$usOcpMulticam = New-UsOcpMulticam
$usCarcDesertTan = New-CarcIndustrialCoating "#B79D70" "us_carc_desert_tan" 78201
$usCarcGreen383 = New-CarcIndustrialCoating "#4D5640" "us_carc_green383" 78223
$usCarcBlackGray = New-CarcIndustrialCoating "#2E3030" "us_carc_blackgray" 78247
$russianEmrSource = Find-SourceImage "russian_emr"
if ($russianEmrSource) {
    $russianEmr = Import-CamoSetFromImage "russian_emr" $russianEmrSource
}
else {
    $russianEmr = New-RussianEmr
}
Save-CamoSet "nato_tricolor_mountain" $nato
Save-CamoSet "turkish_multiterrain" $merdc
Save-CamoSet "edrl_green" $edrl
Save-CamoSet "us_ocp_multicam" $usOcpMulticam
Save-CamoSet "us_carc_desert_tan" $usCarcDesertTan
Save-CamoSet "us_carc_green383" $usCarcGreen383
Save-CamoSet "us_carc_blackgray" $usCarcBlackGray
Save-CamoSet "russian_emr" $russianEmr

$preview = [System.Drawing.Bitmap]::new(4096, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$previewGraphics = [System.Drawing.Graphics]::FromImage($preview)
$previewGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
try {
    $previewGraphics.DrawImage($nato, 0, 0, 512, 512)
    $previewGraphics.DrawImage($merdc, 512, 0, 512, 512)
    $previewGraphics.DrawImage($edrl, 1024, 0, 512, 512)
    $previewGraphics.DrawImage($usOcpMulticam, 1536, 0, 512, 512)
    $previewGraphics.DrawImage($usCarcDesertTan, 2048, 0, 512, 512)
    $previewGraphics.DrawImage($usCarcGreen383, 2560, 0, 512, 512)
    $previewGraphics.DrawImage($usCarcBlackGray, 3072, 0, 512, 512)
    $previewGraphics.DrawImage($russianEmr, 3584, 0, 512, 512)
}
finally {
    $previewGraphics.Dispose()
}
$preview.Save((Join-Path $previewDir "us_mountain_camo_preview.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$preview.Dispose()
$nato.Dispose()
$merdc.Dispose()
$edrl.Dispose()
$usOcpMulticam.Dispose()
$usCarcDesertTan.Dispose()
$usCarcGreen383.Dispose()
$usCarcBlackGray.Dispose()
$russianEmr.Dispose()

Write-Host "Generated NATO coating, Turkish multi-terrain, EDRL green, US OCP MultiCam, US CARC coatings, and Russian EMR textures."
