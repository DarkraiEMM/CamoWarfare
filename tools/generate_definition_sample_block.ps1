$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$textureDir = Join-Path $projectRoot "src\main\resources\assets\camowarfare\textures\block\definition_sample"
$legacyTexturePath = Join-Path $projectRoot "src\main\resources\assets\camowarfare\textures\block\definition_sample_block.png"
$previewPath = Join-Path $projectRoot "preview\definition_sample_block_preview.png"

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function New-Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
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

function New-Alpha([System.Drawing.Color]$Color, [int]$Alpha) {
    return [System.Drawing.Color]::FromArgb($Alpha, $Color.R, $Color.G, $Color.B)
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

function Draw-Line($Graphics, [System.Drawing.Color]$Color, [int]$X1, [int]$Y1, [int]$X2, [int]$Y2, [float]$Width) {
    $pen = [System.Drawing.Pen]::new($Color, $Width)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Square
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Square
    try {
        $Graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2)
    }
    finally {
        $pen.Dispose()
    }
}

function Fill-DigitalCells($Graphics, [System.Drawing.Color]$Color, [int[][]]$Cells, [int]$OffsetCellsX, [int]$OffsetCellsY) {
    foreach ($cell in $Cells) {
        $x = (($cell[0] + $OffsetCellsX) % 16)
        if ($x -lt 0) { $x += 16 }
        $y = (($cell[1] + $OffsetCellsY) % 16)
        if ($y -lt 0) { $y += 16 }
        Fill-Rect $Graphics $Color ($x * 16) ($y * 16) ($cell[2] * 16) ($cell[3] * 16)
        if ($x + $cell[2] -gt 16) {
            Fill-Rect $Graphics $Color (($x - 16) * 16) ($y * 16) ($cell[2] * 16) ($cell[3] * 16)
        }
        if ($y + $cell[3] -gt 16) {
            Fill-Rect $Graphics $Color ($x * 16) (($y - 16) * 16) ($cell[2] * 16) ($cell[3] * 16)
        }
    }
}

function Fill-Ellipse($Graphics, [System.Drawing.Color]$Color, [int]$X, [int]$Y, [int]$Width, [int]$Height) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        $Graphics.FillEllipse($brush, $X, $Y, $Width, $Height)
    }
    finally {
        $brush.Dispose()
    }
}

function Fill-Rivet($Graphics, [System.Drawing.Color]$Outer, [System.Drawing.Color]$Inner, [int]$X, [int]$Y) {
    $highlight = [System.Drawing.Color]::FromArgb(150, 168, 170, 143)
    $shadow = [System.Drawing.Color]::FromArgb(145, 12, 14, 12)
    $rimDark = [System.Drawing.Color]::FromArgb(185, 31, 34, 29)
    try {
        Fill-Ellipse $Graphics $shadow ($X - 4) ($Y - 3) 10 10
        Fill-Ellipse $Graphics $rimDark ($X - 5) ($Y - 5) 10 10
        Fill-Ellipse $Graphics $Outer ($X - 4) ($Y - 4) 8 8
        Fill-Ellipse $Graphics $Inner ($X - 2) ($Y - 2) 5 5
        Fill-Rect $Graphics $highlight ($X - 3) ($Y - 4) 3 2
        Fill-Rect $Graphics ([System.Drawing.Color]::FromArgb(120, 0, 0, 0)) ($X + 1) ($Y + 2) 3 2
    }
    finally {
    }
}

function Draw-BeveledTopEdge($Graphics, [System.Drawing.Color]$Seam) {
    Draw-Line $Graphics (New-Alpha $Seam 190) 0 1 256 1 2.0
    Draw-Line $Graphics (New-Alpha $Seam 120) 0 3 256 3 1.0
    Draw-Line $Graphics ([System.Drawing.Color]::FromArgb(105, 184, 188, 157)) 5 6 251 6 2.0
}

function Draw-BeveledBottomEdge($Graphics, [System.Drawing.Color]$Seam) {
    Draw-Line $Graphics ([System.Drawing.Color]::FromArgb(85, 176, 179, 149)) 5 249 251 249 1.0
    Draw-Line $Graphics (New-Alpha $Seam 135) 0 252 256 252 1.0
    Draw-Line $Graphics (New-Alpha $Seam 205) 0 254 256 254 3.0
}

function Draw-BeveledLeftEdge($Graphics, [System.Drawing.Color]$Seam) {
    Draw-Line $Graphics (New-Alpha $Seam 205) 1 0 1 256 3.0
    Draw-Line $Graphics (New-Alpha $Seam 110) 4 0 4 256 1.0
    Draw-Line $Graphics ([System.Drawing.Color]::FromArgb(85, 184, 188, 157)) 6 5 6 251 1.0
}

function Draw-BeveledRightEdge($Graphics, [System.Drawing.Color]$Seam) {
    Draw-Line $Graphics ([System.Drawing.Color]::FromArgb(70, 184, 188, 157)) 249 5 249 251 1.0
    Draw-Line $Graphics (New-Alpha $Seam 135) 252 0 252 256 1.0
    Draw-Line $Graphics (New-Alpha $Seam 205) 254 0 254 256 3.0
}

function Add-ConnectedEdges([System.Drawing.Bitmap]$Bitmap, [int]$Mask, [bool]$SwapRivetHorizontal) {
    $seam = New-Color "#252821"
    $rivetOuter = New-Color "#4B4E3F"
    $rivetInner = New-Color "#1F211C"
    $graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    try {
        if (($Mask -band 1) -eq 0) {
            Draw-BeveledTopEdge $graphics $seam
        }
        # The connected model's horizontal UV orientation is mirrored in-game, so right/left masks draw swapped.
        if (($Mask -band 8) -eq 0) {
            Draw-BeveledRightEdge $graphics $seam
        }
        if (($Mask -band 4) -eq 0) {
            Draw-BeveledBottomEdge $graphics $seam
        }
        if (($Mask -band 2) -eq 0) {
            Draw-BeveledLeftEdge $graphics $seam
        }
        $topOpen = ($Mask -band 1) -eq 0
        $bottomOpen = ($Mask -band 4) -eq 0
        if ($SwapRivetHorizontal) {
            $rightOpen = ($Mask -band 8) -eq 0
            $leftOpen = ($Mask -band 2) -eq 0
        }
        else {
            $rightOpen = ($Mask -band 2) -eq 0
            $leftOpen = ($Mask -band 8) -eq 0
        }
        if ($topOpen -and $leftOpen) { Fill-Rivet $graphics $rivetOuter $rivetInner 18 18 }
        if ($topOpen -and $rightOpen) { Fill-Rivet $graphics $rivetOuter $rivetInner 238 18 }
        if ($bottomOpen -and $leftOpen) { Fill-Rivet $graphics $rivetOuter $rivetInner 18 238 }
        if ($bottomOpen -and $rightOpen) { Fill-Rivet $graphics $rivetOuter $rivetInner 238 238 }
    }
    finally {
        $graphics.Dispose()
    }
}

function New-ConnectedAtlas([System.Drawing.Bitmap]$Source, [bool]$SwapRivetHorizontal) {
    $atlas = [System.Drawing.Bitmap]::new(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($atlas)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    try {
        for ($mask = 0; $mask -lt 16; $mask++) {
            $tile = $Source.Clone([System.Drawing.Rectangle]::new(0, 0, 256, 256), $Source.PixelFormat)
            Add-ConnectedEdges $tile $mask $SwapRivetHorizontal
            $column = $mask % 4
            $row = [int][Math]::Floor($mask / 4)
            $graphics.DrawImage($tile, [System.Drawing.Rectangle]::new($column * 256, $row * 256, 256, 256))
            $tile.Dispose()
        }
    }
    finally {
        $graphics.Dispose()
    }
    return $atlas
}

function Save-ConnectedMaskTiles([System.Drawing.Bitmap]$Source, [string]$BasePathWithoutExtension, [bool]$SwapRivetHorizontal) {
    for ($mask = 0; $mask -lt 16; $mask++) {
        $tile = $Source.Clone([System.Drawing.Rectangle]::new(0, 0, 256, 256), $Source.PixelFormat)
        Add-ConnectedEdges $tile $mask $SwapRivetHorizontal
        $tile.Save(($BasePathWithoutExtension + "_m" + $mask + ".png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $tile.Dispose()
    }
}

function New-SampleTexture([int]$VariantIndex) {
    $base = New-Color "#8B9075"
    $baseAged = New-Color "#80866E"
    $olive = New-Color "#526747"
    $olive2 = New-Color "#5F704F"
    $brown = New-Color "#735F48"
    $charcoal = New-Color "#2F342F"
    $dust = New-Color "#AAA68A"
    $mud = New-Color "#5C513D"
    $seam = New-Color "#252821"
    $rivetOuter = New-Color "#4B4E3F"
    $rivetInner = New-Color "#1F211C"

    $bitmap = [System.Drawing.Bitmap]::new(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    try {
        $random = [System.Random]::new(121101 + ($VariantIndex * 913))

        $graphics.Clear((Mix-Color $base $baseAged (0.02 * $VariantIndex)))
        $oliveTone = $olive
        if ($VariantIndex % 2 -ne 0) {
            $oliveTone = $olive2
        }
        # Strict single-face budget on a 16x16 cell grid:
        # Base remains roughly 59-60%, disruptive green/brown 25-27%,
        # dark cutting shapes about 10%, dust/highlight about 5%.
        $macroPatterns = @(
            @(
                @($oliveTone, @(0, 4, 5, 7), @(5, 6, 2, 4)),
                @($brown, @(9, 1, 4, 5), @(8, 5, 2, 2)),
                @($charcoal, @(13, 9, 3, 5), @(0, 13, 2, 3), @(13, 0, 2, 2)),
                @($dust, @(0, 0, 4, 2), @(4, 1, 2, 1), @(9, 14, 3, 1))
            ),
            @(
                @($oliveTone, @(10, 0, 5, 8), @(8, 3, 2, 4)),
                @($brown, @(1, 7, 5, 6), @(4, 5, 2, 3)),
                @($charcoal, @(0, 0, 3, 5), @(6, 12, 3, 4), @(14, 13, 2, 2)),
                @($dust, @(11, 12, 4, 2), @(9, 13, 2, 1), @(6, 0, 3, 1))
            ),
            @(
                @($oliveTone, @(0, 0, 5, 7), @(5, 2, 2, 4)),
                @($brown, @(10, 8, 5, 6), @(8, 11, 2, 3)),
                @($charcoal, @(12, 0, 4, 4), @(0, 12, 3, 4), @(14, 4, 2, 2)),
                @($dust, @(0, 9, 4, 2), @(4, 10, 2, 1), @(6, 0, 3, 1))
            ),
            @(
                @($oliveTone, @(11, 0, 5, 9), @(8, 5, 3, 4)),
                @($brown, @(1, 1, 5, 6), @(5, 4, 2, 3)),
                @($charcoal, @(0, 12, 3, 4), @(13, 13, 3, 3), @(14, 9, 2, 2)),
                @($dust, @(7, 0, 4, 2), @(9, 2, 2, 1), @(8, 11, 3, 1))
            )
        )
        foreach ($entry in $macroPatterns[$VariantIndex]) {
            $color = $entry[0]
            for ($part = 1; $part -lt $entry.Count; $part++) {
                $cell = $entry[$part]
                Fill-Rect $graphics $color ($cell[0] * 16) ($cell[1] * 16) ($cell[2] * 16) ($cell[3] * 16)
            }
        }
    }
    finally {
        $graphics.Dispose()
    }

    return $bitmap
}

function Fill-WrappedRect($Graphics, [System.Drawing.Color]$Color, [int]$X, [int]$Y, [int]$Width, [int]$Height, [int]$CanvasSize) {
    $x0 = $X % $CanvasSize
    if ($x0 -lt 0) { $x0 += $CanvasSize }
    $y0 = $Y % $CanvasSize
    if ($y0 -lt 0) { $y0 += $CanvasSize }
    foreach ($dx in @(0, -$CanvasSize)) {
        foreach ($dy in @(0, -$CanvasSize)) {
            $rx = $x0 + $dx
            $ry = $y0 + $dy
            if (($rx + $Width) -gt 0 -and $rx -lt $CanvasSize -and ($ry + $Height) -gt 0 -and $ry -lt $CanvasSize) {
                Fill-Rect $Graphics $Color $rx $ry $Width $Height
            }
        }
    }
}

function Add-MacroPatch($Graphics, [System.Drawing.Color]$Color, [int]$Cell, [int[][]]$Cells) {
    foreach ($cellRect in $Cells) {
        Fill-WrappedRect $Graphics $Color ($cellRect[0] * $Cell) ($cellRect[1] * $Cell) ($cellRect[2] * $Cell) ($cellRect[3] * $Cell) 512
    }
}

function New-MasterTexture {
    $base = New-Color "#A09B7C"
    $baseShade = New-Color "#8A866B"
    $olive = New-Color "#536044"
    $olive2 = New-Color "#47543D"
    $brown = New-Color "#715A40"
    $charcoal = New-Color "#282D28"
    $dust = New-Color "#B8B18F"

    $bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    try {
        $graphics.Clear($base)

        for ($y = 0; $y -lt 512; $y += 16) {
            for ($x = 0; $x -lt 512; $x += 16) {
                $hash = [Math]::Sin(($x * 0.173) + ($y * 0.311) + 42.0) * 43758.5453
                $fract = $hash - [Math]::Floor($hash)
                if ($fract -lt 0.22) {
                    Fill-Rect $graphics (Mix-Color $base $baseShade 0.22) $x $y 16 16
                }
            }
        }

        $cell = 8

        Add-MacroPatch $graphics $olive $cell @(
            @(0, 7, 9, 9), @(7, 10, 4, 5), @(0, 16, 5, 4),
            @(13, 1, 9, 8), @(22, 4, 5, 4), @(15, 9, 4, 3),
            @(30, 0, 9, 6), @(28, 6, 6, 6), @(34, 10, 4, 3),
            @(45, 2, 10, 8), @(42, 9, 6, 6), @(52, 10, 5, 4),
            @(5, 24, 11, 7), @(2, 30, 7, 5), @(13, 31, 5, 4),
            @(24, 25, 10, 8), @(21, 32, 7, 5), @(31, 33, 5, 4),
            @(42, 25, 11, 8), @(39, 32, 7, 5), @(50, 33, 5, 4),
            @(12, 45, 10, 8), @(8, 52, 7, 5), @(21, 51, 4, 4),
            @(32, 44, 10, 8), @(29, 51, 6, 5), @(40, 52, 5, 4),
            @(54, 47, 8, 8), @(49, 54, 8, 5), @(60, 55, 4, 4)
        )

        Add-MacroPatch $graphics $olive2 $cell @(
            @(1, 0, 8, 6), @(0, 5, 5, 3), @(8, 3, 3, 3),
            @(20, 14, 10, 7), @(17, 20, 6, 4), @(28, 19, 4, 3),
            @(37, 15, 9, 7), @(44, 20, 5, 4), @(35, 21, 4, 3),
            @(57, 15, 7, 8), @(54, 22, 4, 4), @(62, 11, 2, 4),
            @(0, 39, 8, 8), @(7, 43, 4, 4), @(0, 47, 4, 4),
            @(22, 56, 11, 6), @(19, 61, 6, 3), @(31, 62, 5, 2),
            @(46, 40, 10, 7), @(43, 46, 6, 5), @(55, 45, 5, 4)
        )

        Add-MacroPatch $graphics $brown $cell @(
            @(12, 0, 5, 7), @(10, 6, 4, 3), @(16, 5, 3, 4),
            @(31, 8, 7, 5), @(28, 12, 4, 4), @(37, 13, 3, 3),
            @(49, 18, 7, 6), @(46, 23, 4, 3), @(55, 21, 4, 4),
            @(3, 33, 7, 6), @(0, 38, 5, 4), @(9, 37, 3, 3),
            @(23, 38, 7, 6), @(20, 43, 4, 3), @(30, 42, 4, 4),
            @(39, 57, 8, 5), @(36, 61, 5, 3), @(46, 60, 3, 4),
            @(59, 30, 5, 7), @(56, 36, 4, 3), @(63, 37, 1, 3)
        )

        Add-MacroPatch $graphics $charcoal $cell @(
            @(0, 10, 4, 5), @(4, 14, 2, 3),
            @(19, 5, 4, 5), @(22, 9, 3, 3),
            @(38, 3, 5, 4), @(36, 7, 3, 3),
            @(30, 20, 4, 4), @(34, 23, 2, 3),
            @(10, 36, 5, 4), @(8, 40, 3, 3),
            @(50, 36, 5, 5), @(47, 40, 3, 3),
            @(58, 57, 4, 5), @(62, 60, 2, 3)
        )

        Add-MacroPatch $graphics $dust $cell @(
            @(0, 0, 6, 2), @(5, 2, 4, 1),
            @(25, 2, 4, 2), @(27, 4, 3, 1),
            @(40, 11, 5, 2), @(45, 13, 3, 1),
            @(16, 24, 6, 2), @(21, 26, 3, 1),
            @(34, 34, 5, 2), @(39, 36, 3, 1),
            @(6, 55, 6, 2), @(12, 57, 3, 1),
            @(52, 4, 5, 2), @(57, 6, 3, 1)
        )

        $random = [System.Random]::new(5121211)
        for ($i = 0; $i -lt 1400; $i++) {
            $x = $random.Next(0, 512)
            $y = $random.Next(0, 512)
            $source = $base
            if ($random.NextDouble() -lt 0.45) { $source = $baseShade }
            $noise = Mix-Color $source (New-Color "#111111") ($random.NextDouble() * 0.10)
            Fill-Rect $graphics (New-Alpha $noise 32) $x $y 1 1
        }
    }
    finally {
        $graphics.Dispose()
    }
    return $bitmap
}

function New-EdgeTexture {
    $bitmap = [System.Drawing.Bitmap]::new(16, 16, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    try {
        $graphics.Clear([System.Drawing.Color]::FromArgb(205, 33, 37, 31))
        Fill-Rect $graphics ([System.Drawing.Color]::FromArgb(125, 162, 166, 134)) 1 1 14 2
        Fill-Rect $graphics ([System.Drawing.Color]::FromArgb(105, 8, 10, 8)) 12 0 4 16
        Fill-Rect $graphics ([System.Drawing.Color]::FromArgb(120, 8, 10, 8)) 0 12 16 4
    }
    finally {
        $graphics.Dispose()
    }
    return $bitmap
}

function New-RivetTexture {
    $bitmap = [System.Drawing.Bitmap]::new(16, 16, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    try {
        $graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        Fill-Ellipse $graphics ([System.Drawing.Color]::FromArgb(140, 8, 9, 8)) 3 4 10 10
        Fill-Ellipse $graphics ([System.Drawing.Color]::FromArgb(255, 58, 62, 51)) 2 2 11 11
        Fill-Ellipse $graphics ([System.Drawing.Color]::FromArgb(255, 25, 28, 24)) 5 5 6 6
        Fill-Rect $graphics ([System.Drawing.Color]::FromArgb(150, 155, 160, 132)) 4 3 4 2
    }
    finally {
        $graphics.Dispose()
    }
    return $bitmap
}

Ensure-Directory $textureDir
Ensure-Directory (Split-Path -Parent $legacyTexturePath)
Ensure-Directory (Split-Path -Parent $previewPath)

$master = New-MasterTexture
$master.Save((Join-Path $textureDir "master.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$master.Save((Join-Path $textureDir "variant_0.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$master.Save($legacyTexturePath, [System.Drawing.Imaging.ImageFormat]::Png)

$item = $master.Clone([System.Drawing.Rectangle]::new(64, 64, 256, 256), $master.PixelFormat)
$item.Save((Join-Path $textureDir "item.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$item.Save((Join-Path $textureDir "variant_1.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$item.Dispose()

$edge = New-EdgeTexture
$edge.Save((Join-Path $textureDir "edge.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$edge.Dispose()

$rivet = New-RivetTexture
$rivet.Save((Join-Path $textureDir "rivet.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$rivet.Dispose()

$preview = [System.Drawing.Bitmap]::new(1024, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$pg = [System.Drawing.Graphics]::FromImage($preview)
$pg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$pg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$pg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
try {
    $pg.Clear([System.Drawing.Color]::FromArgb(224, 224, 220))
    $pg.DrawImage($master, [System.Drawing.Rectangle]::new(24, 0, 512, 512))
    for ($y = 0; $y -lt 3; $y++) {
        for ($x = 0; $x -lt 4; $x++) {
            $source = [System.Drawing.Rectangle]::new(($x + 3) * 32, ($y + 4) * 32, 32, 32)
            $target = [System.Drawing.Rectangle]::new(580 + ($x * 96), 48 + ($y * 128), 80, 80)
            $pg.DrawImage($master, $target, $source, [System.Drawing.GraphicsUnit]::Pixel)
        }
    }
}
finally {
    $pg.Dispose()
}
$preview.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
$preview.Dispose()
$master.Dispose()

Write-Host "Generated 512x512 position-tiled definition sample textures in $textureDir"
Write-Host "Generated $previewPath"
