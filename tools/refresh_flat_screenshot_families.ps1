[CmdletBinding()]
param(
    [string[]]$FamilyIds
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $root "src\main\resources\assets\camowarfare"
$blockTextureRoot = Join-Path $assetsRoot "textures\block"

$families = @(
    @{ Id = "pla_mountain"; Style = "macro"; Palette = @("#6E725B", "#989071", "#556149", "#7B6047") },
    @{ Id = "pla_mountain_digital"; Style = "digital"; Palette = @("#6E725B", "#978E6F", "#556149", "#3A4534") },
    @{ Id = "winter_whitewash"; Style = "macro"; Palette = @("#E9EEEB", "#F9FBFA", "#C8D0D2", "#AEB8B5") },
    @{ Id = "winter_whitewash_hull"; Style = "hull"; Palette = @("#E2E7E4", "#F6F8F7", "#C3CCCA", "#9EAAA7") },
    @{ Id = "snow_graywhite_camo"; Style = "macro"; Palette = @("#DCE2E2", "#F6F8F6", "#C0C8CC", "#96A1A8") },
    @{ Id = "snow_graywhite_digital"; Style = "digital"; Palette = @("#E2E7E5", "#FBFCFB", "#C9D0D3", "#A4AEB4") },
    @{ Id = "snow_graywhite_splinter"; Style = "splinter"; Palette = @("#E1E6E3", "#FAFBFA", "#C0C8CC", "#A2ADB3") },

    @{ Id = "black_night"; Style = "macro"; Palette = @("#252A30", "#343C45", "#1E242A", "#14191D") },
    @{ Id = "night_lowvis_camo"; Style = "macro"; Palette = @("#2B3138", "#3C454E", "#242B31", "#181D21") },
    @{ Id = "night_lowvis_digital"; Style = "digital"; Palette = @("#2A3037", "#39424B", "#232A30", "#171C20") },
    @{ Id = "night_lowvis_splinter"; Style = "splinter"; Palette = @("#293038", "#38414A", "#22282E", "#161B1F") },
    @{ Id = "black_night_hull"; Style = "hull"; Palette = @("#262C32", "#363F48", "#1D2329", "#13181C") },

    @{ Id = "naval_bluegray"; Style = "macro"; Palette = @("#667382", "#8091A2", "#465363", "#2E3945") },
    @{ Id = "naval_bluegray_camo"; Style = "macro"; Palette = @("#313E4B", "#435465", "#5F7387", "#93A6B8") },
    @{ Id = "naval_bluegray_digital"; Style = "digital"; Palette = @("#667381", "#8394A4", "#495765", "#2E3946") },
    @{ Id = "naval_bluegray_splinter"; Style = "splinter"; Palette = @("#647282", "#8494A5", "#495563", "#2F3944") },

    @{ Id = "pla_05_naval_blue"; Style = "macro"; Palette = @("#7E9FD2", "#E4ECF7", "#4D74B2", "#1E4F8E") },
    @{ Id = "pla_05_naval_blue_hull"; Style = "hull"; Palette = @("#5E83BC", "#8FAEDA", "#355D96", "#E0E8F3") },
    @{ Id = "pla_05_naval_blue_riveted"; Style = "macro_riveted"; Palette = @("#6F92C8", "#EDF2FA", "#446CB0", "#253C71") },

    @{ Id = "urban_gray_camo"; Style = "macro"; Palette = @("#81868C", "#A2A9B1", "#676E76", "#494F57") },
    @{ Id = "urban_gray_digital"; Style = "digital"; Palette = @("#7F858B", "#A0A8B0", "#676E76", "#474D55") },
    @{ Id = "urban_gray_splinter"; Style = "splinter"; Palette = @("#7E848A", "#9FA7AF", "#676E76", "#494F57") },
    @{ Id = "urban_digital_hull"; Style = "hull"; Palette = @("#727A83", "#8E97A1", "#59616A", "#3D444C") }
)

function Ensure-Dir([string]$Path) {
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

function New-BlockPolygon(
    [double]$CenterX,
    [double]$CenterY,
    [double]$RadiusX,
    [double]$RadiusY,
    [double]$Angle
) {
    $cos = [Math]::Cos($Angle)
    $sin = [Math]::Sin($Angle)
    $corners = @(
        @(-1.00, -0.68),
        @(0.48, -1.00),
        @(1.00, -0.04),
        @(0.56, 0.88),
        @(-0.32, 1.00),
        @(-1.00, 0.36)
    )

    $points = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    foreach ($corner in $corners) {
        $x = $corner[0] * $RadiusX
        $y = $corner[1] * $RadiusY
        $rx = ($x * $cos) - ($y * $sin)
        $ry = ($x * $sin) + ($y * $cos)
        $points.Add([System.Drawing.PointF]::new([float]($CenterX + $rx), [float]($CenterY + $ry)))
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
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length * $TipFactor - $perpX * ($half * 0.50)), [float]($CenterY + $dirY * $Length * $TipFactor - $perpY * ($half * 0.50))),
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length), [float]($CenterY + $dirY * $Length)),
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length * $TipFactor + $perpX * ($half * 0.50)), [float]($CenterY + $dirY * $Length * $TipFactor + $perpY * ($half * 0.50))),
        [System.Drawing.PointF]::new([float]($CenterX - $dirX * $Length * $TailFactor + $perpX * $half), [float]($CenterY - $dirY * $Length * $TailFactor + $perpY * $half))
    )
}

function Paint-MacroStyle(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color[]]$Palette
) {
    for ($i = 0; $i -lt 3; $i++) {
        $polygon = New-BlockPolygon `
            -CenterX (20 + $Random.NextDouble() * 88) `
            -CenterY (20 + $Random.NextDouble() * 88) `
            -RadiusX (22 + $Random.NextDouble() * 18) `
            -RadiusY (18 + $Random.NextDouble() * 16) `
            -Angle (($Random.NextDouble() * 1.35) - 0.65)
        Fill-WrappedPolygon $Graphics $Palette[1] $polygon 128
    }

    for ($i = 0; $i -lt 2; $i++) {
        $polygon = New-BlockPolygon `
            -CenterX (18 + $Random.NextDouble() * 92) `
            -CenterY (18 + $Random.NextDouble() * 92) `
            -RadiusX (18 + $Random.NextDouble() * 16) `
            -RadiusY (14 + $Random.NextDouble() * 14) `
            -Angle (($Random.NextDouble() * 1.45) - 0.72)
        Fill-WrappedPolygon $Graphics $Palette[2] $polygon 128
    }

    $accent = New-BlockPolygon `
        -CenterX (24 + $Random.NextDouble() * 80) `
        -CenterY (24 + $Random.NextDouble() * 80) `
        -RadiusX (12 + $Random.NextDouble() * 12) `
        -RadiusY (10 + $Random.NextDouble() * 10) `
        -Angle (($Random.NextDouble() * 1.2) - 0.6)
    Fill-WrappedPolygon $Graphics $Palette[3] $accent 128
}

function Paint-DigitalStyle(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color[]]$Palette
) {
    $cellSize = 8
    $gridSize = 16

    foreach ($colorIndex in 1..3) {
        $clusterCount = 9 - $colorIndex
        for ($cluster = 0; $cluster -lt $clusterCount; $cluster++) {
            $x = $Random.Next($gridSize)
            $y = $Random.Next($gridSize)
            $steps = 4 + $Random.Next(5)
            for ($step = 0; $step -lt $steps; $step++) {
                $w = 1 + $Random.Next(3)
                $h = 1 + $Random.Next(2)
                Fill-WrappedRect $Graphics $Palette[$colorIndex] ($x * $cellSize) ($y * $cellSize) ($w * $cellSize) ($h * $cellSize) 128
                switch ($Random.Next(4)) {
                    0 { $x = ($x + 1) % $gridSize }
                    1 { $x = ($x - 1 + $gridSize) % $gridSize }
                    2 { $y = ($y + 1) % $gridSize }
                    default { $y = ($y - 1 + $gridSize) % $gridSize }
                }
            }
        }
    }
}

function Paint-SplinterStyle(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color[]]$Palette
) {
    for ($i = 0; $i -lt 3; $i++) {
        $band = New-BandPolygon `
            -CenterX (18 + $Random.NextDouble() * 92) `
            -CenterY (18 + $Random.NextDouble() * 92) `
            -Length (30 + $Random.NextDouble() * 22) `
            -Thickness (16 + $Random.NextDouble() * 10) `
            -Angle (($Random.NextDouble() * 1.30) - 0.62) `
            -TailFactor (0.46 + $Random.NextDouble() * 0.14) `
            -TipFactor (0.48 + $Random.NextDouble() * 0.12)
        Fill-WrappedPolygon $Graphics $Palette[1] $band 128
    }

    for ($i = 0; $i -lt 2; $i++) {
        $band = New-BandPolygon `
            -CenterX (16 + $Random.NextDouble() * 96) `
            -CenterY (16 + $Random.NextDouble() * 96) `
            -Length (26 + $Random.NextDouble() * 18) `
            -Thickness (12 + $Random.NextDouble() * 8) `
            -Angle (($Random.NextDouble() * 1.36) - 0.68) `
            -TailFactor (0.42 + $Random.NextDouble() * 0.12) `
            -TipFactor (0.44 + $Random.NextDouble() * 0.10)
        Fill-WrappedPolygon $Graphics $Palette[2] $band 128
    }

    $accent = New-BandPolygon `
        -CenterX (20 + $Random.NextDouble() * 88) `
        -CenterY (20 + $Random.NextDouble() * 88) `
        -Length (22 + $Random.NextDouble() * 16) `
        -Thickness (8 + $Random.NextDouble() * 6) `
        -Angle (($Random.NextDouble() * 1.40) - 0.70) `
        -TailFactor 0.42 `
        -TipFactor 0.42
    Fill-WrappedPolygon $Graphics $Palette[3] $accent 128
}

function Paint-HullStyle(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color[]]$Palette
) {
    $panel = New-BlockPolygon `
        -CenterX (28 + $Random.NextDouble() * 72) `
        -CenterY (26 + $Random.NextDouble() * 76) `
        -RadiusX (24 + $Random.NextDouble() * 18) `
        -RadiusY (16 + $Random.NextDouble() * 12) `
        -Angle (($Random.NextDouble() * 1.10) - 0.55)
    Fill-WrappedPolygon $Graphics $Palette[0] $panel 128

    $band = New-BandPolygon `
        -CenterX (22 + $Random.NextDouble() * 84) `
        -CenterY (22 + $Random.NextDouble() * 84) `
        -Length (26 + $Random.NextDouble() * 18) `
        -Thickness (10 + $Random.NextDouble() * 7) `
        -Angle (($Random.NextDouble() * 1.12) - 0.56) `
        -TailFactor 0.45 `
        -TipFactor 0.46
    Fill-WrappedPolygon $Graphics $Palette[2] $band 128

    if ($Random.NextDouble() -gt 0.35) {
        $accent = New-BlockPolygon `
            -CenterX (28 + $Random.NextDouble() * 72) `
            -CenterY (28 + $Random.NextDouble() * 72) `
            -RadiusX (10 + $Random.NextDouble() * 10) `
            -RadiusY (8 + $Random.NextDouble() * 8) `
            -Angle (($Random.NextDouble() * 1.0) - 0.5)
        Fill-WrappedPolygon $Graphics $Palette[3] $accent 128
    }
}

function New-NauticalBandPolygon(
    [double]$CenterX,
    [double]$CenterY,
    [double]$Length,
    [double]$Thickness,
    [double]$Angle
) {
    $dirX = [Math]::Cos($Angle)
    $dirY = [Math]::Sin($Angle)
    $perpX = -$dirY
    $perpY = $dirX
    $half = $Thickness / 2.0

    return @(
        [System.Drawing.PointF]::new([float]($CenterX - $dirX * $Length * 0.58 - $perpX * $half), [float]($CenterY - $dirY * $Length * 0.58 - $perpY * $half)),
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length * 0.30 - $perpX * ($half * 0.86)), [float]($CenterY + $dirY * $Length * 0.30 - $perpY * ($half * 0.86))),
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length - $perpX * ($half * 0.22)), [float]($CenterY + $dirY * $Length - $perpY * ($half * 0.22))),
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length + $perpX * ($half * 0.22)), [float]($CenterY + $dirY * $Length + $perpY * ($half * 0.22))),
        [System.Drawing.PointF]::new([float]($CenterX + $dirX * $Length * 0.30 + $perpX * ($half * 0.86)), [float]($CenterY + $dirY * $Length * 0.30 + $perpY * ($half * 0.86))),
        [System.Drawing.PointF]::new([float]($CenterX - $dirX * $Length * 0.58 + $perpX * $half), [float]($CenterY - $dirY * $Length * 0.58 + $perpY * $half))
    )
}

function Paint-NavalDigitalStyle(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color[]]$Palette,
    [bool]$HullMode = $false
) {
    $tileSize = 128

    for ($row = 0; $row -lt 5; $row++) {
        $bandY = 12 + ($row * 24) + ($Random.NextDouble() * 6)
        $baseAngle = (($Random.NextDouble() * 0.28) - 0.14)

        for ($segment = 0; $segment -lt (6 + $Random.Next(2)); $segment++) {
            $centerX = -8 + ($segment * 24) + ($Random.NextDouble() * 10)
            $centerY = $bandY + (($Random.NextDouble() * 5) - 2.5)
            $length = 16 + ($Random.NextDouble() * 10)
            $thickness = if ($HullMode) { 7 + ($Random.NextDouble() * 4) } else { 8 + ($Random.NextDouble() * 5) }
            $angle = $baseAngle + (($Random.NextDouble() * 0.20) - 0.10)
            $color = if (($segment + $row) % 3 -eq 0) { $Palette[2] } else { $Palette[1] }
            $polygon = New-NauticalBandPolygon -CenterX $centerX -CenterY $centerY -Length $length -Thickness $thickness -Angle $angle
            Fill-WrappedPolygon $Graphics $color $polygon $tileSize

            if (-not $HullMode -and $Random.NextDouble() -gt 0.55) {
                $cellX = [Math]::Round($centerX / 4) * 4
                $cellY = [Math]::Round($centerY / 4) * 4
                Fill-WrappedRect $Graphics $Palette[3] $cellX $cellY 8 4 $tileSize
            }
        }
    }

    $accentCount = if ($HullMode) { 3 } else { 6 }
    for ($i = 0; $i -lt $accentCount; $i++) {
        $x = ($Random.Next(28) * 4)
        $y = ($Random.Next(28) * 4)
        $w = 4 + ($Random.Next(3) * 4)
        $h = 4 + ($Random.Next(2) * 4)
        Fill-WrappedRect $Graphics $Palette[3] $x $y $w $h $tileSize
    }
}

function Add-RivetedOverlay(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color[]]$Palette
) {
    for ($i = 0; $i -lt 3; $i++) {
        $x = 18 + ($Random.NextDouble() * 84)
        $y = 12 + ($Random.NextDouble() * 80)
        $height = 28 + $Random.Next(26)
        Fill-WrappedRect $Graphics $Palette[2] $x $y 2 $height 128
        for ($j = 0; $j -lt 4; $j++) {
            $ry = $y + 5 + ($j * 10)
            Fill-WrappedRect $Graphics $Palette[3] ($x - 1) $ry 4 4 128
        }
    }
}

function Add-StainedOverlay(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color[]]$Palette
) {
    for ($i = 0; $i -lt 4; $i++) {
        $x = 16 + ($Random.NextDouble() * 90)
        $y = 16 + ($Random.NextDouble() * 72)
        $w = 8 + $Random.Next(12)
        $h = 20 + $Random.Next(18)
        Fill-WrappedRect $Graphics $Palette[2] $x $y $w $h 128
        Fill-WrappedRect $Graphics $Palette[3] ($x + ($w * 0.35)) ($y + 3) ([Math]::Max(3, $w * 0.3)) ([Math]::Max(10, $h - 6)) 128
    }
}

function Add-WeatheredOverlay(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color[]]$Palette
) {
    for ($i = 0; $i -lt 10; $i++) {
        $x = 10 + ($Random.NextDouble() * 108)
        $y = 10 + ($Random.NextDouble() * 108)
        $w = 4 + $Random.Next(8)
        Fill-WrappedRect $Graphics $Palette[3] $x $y $w 2 128
        if ($Random.NextDouble() -gt 0.45) {
            Fill-WrappedRect $Graphics $Palette[2] ($x + 1) ($y + 1) ([Math]::Max(2, $w - 2)) 1 128
        }
    }
}

function New-FlatTexture([string]$FamilyId, [string]$Variant, [string]$Style, [System.Drawing.Color[]]$Palette) {
    $bitmap = New-Bitmap 128 128
    $random = New-SeedRandom "$FamilyId-$Variant"

    Use-Graphics $bitmap {
        param($graphics)
        $graphics.Clear($Palette[0])
        switch ($Style) {
            "macro" { Paint-MacroStyle $graphics $random $Palette }
            "digital" { Paint-DigitalStyle $graphics $random $Palette }
            "splinter" { Paint-SplinterStyle $graphics $random $Palette }
            "hull" { Paint-HullStyle $graphics $random $Palette }
            "naval_digital" { Paint-NavalDigitalStyle $graphics $random $Palette }
            "naval_hull" { Paint-NavalDigitalStyle $graphics $random $Palette $true }
            "naval_digital_riveted" {
                Paint-NavalDigitalStyle $graphics $random $Palette
                Add-RivetedOverlay $graphics $random $Palette
            }
            "naval_digital_stained" {
                Paint-NavalDigitalStyle $graphics $random $Palette
                Add-StainedOverlay $graphics $random $Palette
            }
            "naval_digital_weathered" {
                Paint-NavalDigitalStyle $graphics $random $Palette
                Add-WeatheredOverlay $graphics $random $Palette
            }
            "macro_riveted" {
                Paint-MacroStyle $graphics $random $Palette
                Add-RivetedOverlay $graphics $random $Palette
            }
            "macro_stained" {
                Paint-MacroStyle $graphics $random $Palette
                Add-StainedOverlay $graphics $random $Palette
            }
            "riveted" {
                Paint-HullStyle $graphics $random $Palette
                Add-RivetedOverlay $graphics $random $Palette
            }
            "stained" {
                Paint-HullStyle $graphics $random $Palette
                Add-StainedOverlay $graphics $random $Palette
            }
            "weathered" {
                Paint-HullStyle $graphics $random $Palette
                Add-WeatheredOverlay $graphics $random $Palette
            }
        }
    }

    return $bitmap
}

foreach ($family in $families) {
    if ($FamilyIds -and $family.Id -notin $FamilyIds) {
        continue
    }

    $dir = Join-Path $blockTextureRoot $family.Id
    Ensure-Dir $dir
    $palette = @($family.Palette | ForEach-Object { [System.Drawing.ColorTranslator]::FromHtml($_) })

    foreach ($variant in @("a", "b", "c", "d")) {
        $bitmap = New-FlatTexture $family.Id $variant $family.Style $palette
        try {
            $bitmap.Save((Join-Path $dir ($variant + ".png")), [System.Drawing.Imaging.ImageFormat]::Png)
            $bitmap.Save((Join-Path $dir ($variant + "_atlas.png")), [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bitmap.Dispose()
        }
    }
}

Write-Output "flat screenshot families refreshed"
