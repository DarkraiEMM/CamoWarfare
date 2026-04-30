$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$resourcesRoot = Join-Path $projectRoot "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"

$families = @(
    [ordered]@{ Id = "nato_woodland"; Zh = "NATO Woodland"; En = "NATO Woodland"; Legacy = "nato_woodland_block"; Type = "macro"; Palette = @("#556B2F", "#6E7A43", "#3A4424", "#8A6F47") },
    [ordered]@{ Id = "russian_green_splinter"; Zh = "Russian Green Splinter"; En = "Russian Green Splinter"; Legacy = "russian_green_splinter_block"; Type = "splinter"; Palette = @("#5A6F3A", "#748548", "#394626", "#2A321B") },
    [ordered]@{ Id = "russian_desert"; Zh = "Russian Desert"; En = "Russian Desert"; Legacy = "russian_desert_block"; Type = "macro"; Palette = @("#A98C62", "#C2A67A", "#7E6341", "#5C452A") },
    [ordered]@{ Id = "nato_desert"; Zh = "NATO Desert"; En = "NATO Desert"; Legacy = "nato_desert_block"; Type = "macro"; Palette = @("#B79A68", "#D1B589", "#7A5E38", "#9A7E52") },
    [ordered]@{ Id = "woodland_digital"; Zh = "Woodland Digital"; En = "Woodland Digital"; Legacy = "woodland_digital_block"; Type = "digital"; Palette = @("#566842", "#728356", "#39492C", "#1F2619") },
    [ordered]@{ Id = "desert_digital"; Zh = "Desert Digital"; En = "Desert Digital"; Legacy = "desert_digital_block"; Type = "digital"; Palette = @("#C8AB7C", "#E0C79D", "#A68155", "#725032") },
    [ordered]@{ Id = "urban_digital"; Zh = "Urban Digital"; En = "Urban Digital"; Legacy = "urban_digital_block"; Type = "digital"; Palette = @("#98A0A6", "#C5CDD1", "#6A7379", "#41484D") },
    [ordered]@{ Id = "naval_bluegray"; Zh = "Naval Blue-Gray"; En = "Naval Blue-Gray"; Legacy = "naval_bluegray_block"; Type = "macro"; Palette = @("#6F7F89", "#8F9EA8", "#51606A", "#313C45") },
    [ordered]@{ Id = "winter_whitewash"; Zh = "Winter Whitewash"; En = "Winter Whitewash"; Legacy = "winter_whitewash_block"; Type = "winter"; Palette = @("#E7E8E5", "#C8CDD0", "#A5AEB5", "#848B91") },
    [ordered]@{ Id = "black_night"; Zh = "Black Night"; En = "Black Night"; Legacy = "black_night_block"; Type = "night"; Palette = @("#1D2125", "#343A3F", "#4A545A", "#6C757D") },
    [ordered]@{ Id = "solid_military_green"; Zh = "Solid Military Green"; En = "Solid Military Green"; Legacy = $null; Type = "solid"; Palette = @("#5D6E42", "#718151", "#495736", "#334027") },
    [ordered]@{ Id = "solid_desert_sand"; Zh = "Solid Desert Sand"; En = "Solid Desert Sand"; Legacy = $null; Type = "solid"; Palette = @("#BB9C65", "#D1B17A", "#9A7D4F", "#7A603A") },
    [ordered]@{ Id = "solid_bluegray"; Zh = "Solid Blue-Gray"; En = "Solid Blue-Gray"; Legacy = $null; Type = "solid"; Palette = @("#70808B", "#8697A1", "#58656F", "#3F4A52") },
    [ordered]@{ Id = "solid_night_black"; Zh = "Solid Night Black"; En = "Solid Night Black"; Legacy = $null; Type = "solid"; Palette = @("#25282C", "#3B4146", "#171A1D", "#50575D") }

$variants = @(
    [ordered]@{ Id = "a"; Label = "A" },
    [ordered]@{ Id = "b"; Label = "B" },
    [ordered]@{ Id = "c"; Label = "C" }
)

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Reset-Directory([string]$Path) {
    if (Test-Path $Path) {
        Remove-Item -Recurse -Force $Path
    }
    New-Item -ItemType Directory -Path $Path | Out-Null
}

function Get-StableSeed([string]$Text) {
    $hash = [int64]2166136261
    foreach ($char in $Text.ToCharArray()) {
        $hash = ($hash -bxor [int64][char]$char)
        $hash = ($hash * 16777619) % 4294967296
    }
    return [int]($hash -band 0x7FFFFFFF)
}

function New-Random([string]$Key) {
    return [System.Random]::new((Get-StableSeed $Key))
}

function ConvertTo-Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function Mix-Color([System.Drawing.Color]$ColorA, [System.Drawing.Color]$ColorB, [double]$WeightB) {
    $weightA = 1.0 - $WeightB
    $r = [int][Math]::Round(($ColorA.R * $weightA) + ($ColorB.R * $WeightB))
    $g = [int][Math]::Round(($ColorA.G * $weightA) + ($ColorB.G * $WeightB))
    $b = [int][Math]::Round(($ColorA.B * $weightA) + ($ColorB.B * $WeightB))
    $r = [Math]::Min(255, [Math]::Max(0, $r))
    $g = [Math]::Min(255, [Math]::Max(0, $g))
    $b = [Math]::Min(255, [Math]::Max(0, $b))
    return [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
}

function New-Bitmap([int]$Width, [int]$Height) {
    return [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function Use-Graphics([System.Drawing.Bitmap]$Bitmap, [scriptblock]$Script) {
    $graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighSpeed
    try {
        & $Script $graphics
    }
    finally {
        $graphics.Dispose()
    }
}

function Shift-Points([System.Drawing.PointF[]]$Points, [float]$OffsetX, [float]$OffsetY) {
    $shifted = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    foreach ($point in $Points) {
        $shifted.Add([System.Drawing.PointF]::new($point.X + $OffsetX, $point.Y + $OffsetY))
    }
    return $shifted.ToArray()
}

function Invoke-Wrapped([int]$TileSize, [scriptblock]$Script) {
    foreach ($offsetX in @(-$TileSize, 0, $TileSize)) {
        foreach ($offsetY in @(-$TileSize, 0, $TileSize)) {
            & $Script $offsetX $offsetY
        }
    }
}

function Fill-WrappedRect([System.Drawing.Graphics]$Graphics, [System.Drawing.Color]$Color, [float]$X, [float]$Y, [float]$Width, [float]$Height, [int]$TileSize) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        Invoke-Wrapped $TileSize {
            param($OffsetX, $OffsetY)
            $Graphics.FillRectangle($brush, $X + $OffsetX, $Y + $OffsetY, $Width, $Height)
        }
    }
    finally {
        $brush.Dispose()
    }
}

function Fill-WrappedEllipse([System.Drawing.Graphics]$Graphics, [System.Drawing.Color]$Color, [float]$X, [float]$Y, [float]$Width, [float]$Height, [int]$TileSize) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        Invoke-Wrapped $TileSize {
            param($OffsetX, $OffsetY)
            $Graphics.FillEllipse($brush, $X + $OffsetX, $Y + $OffsetY, $Width, $Height)
        }
    }
    finally {
        $brush.Dispose()
    }
}

function Fill-WrappedPolygon([System.Drawing.Graphics]$Graphics, [System.Drawing.Color]$Color, [System.Drawing.PointF[]]$Points, [int]$TileSize) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        Invoke-Wrapped $TileSize {
            param($OffsetX, $OffsetY)
            $Graphics.FillPolygon($brush, (Shift-Points $Points $OffsetX $OffsetY))
        }
    }
    finally {
        $brush.Dispose()
    }
}

function Fill-WrappedLine([System.Drawing.Graphics]$Graphics, [System.Drawing.Color]$Color, [float]$X1, [float]$Y1, [float]$X2, [float]$Y2, [float]$Thickness, [int]$TileSize) {
    $pen = [System.Drawing.Pen]::new($Color, $Thickness)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    try {
        Invoke-Wrapped $TileSize {
            param($OffsetX, $OffsetY)
            $Graphics.DrawLine($pen, $X1 + $OffsetX, $Y1 + $OffsetY, $X2 + $OffsetX, $Y2 + $OffsetY)
        }
    }
    finally {
        $pen.Dispose()
    }
}

function New-PolygonPoints([System.Random]$Random, [int]$CenterX, [int]$CenterY, [int]$RadiusMin, [int]$RadiusMax, [int]$Count) {
    $points = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    for ($index = 0; $index -lt $Count; $index++) {
        $angle = (($index / [double]$Count) * [Math]::PI * 2.0) + ($Random.NextDouble() * 0.55)
        $radius = $RadiusMin + $Random.Next($RadiusMax - $RadiusMin + 1)
        $x = $CenterX + [Math]::Cos($angle) * $radius
        $y = $CenterY + [Math]::Sin($angle) * $radius
        $points.Add([System.Drawing.PointF]::new([float]$x, [float]$y))
    }
    return $points.ToArray()
}

function New-ClippedClone([System.Drawing.Bitmap]$Source) {
    return $Source.Clone([System.Drawing.Rectangle]::new(0, 0, $Source.Width, $Source.Height), $Source.PixelFormat)
}

function Draw-MacroPattern([System.Drawing.Bitmap]$Bitmap, [hashtable]$Family, [System.Random]$Random) {
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($colors[0])
        for ($i = 0; $i -lt 24; $i++) {
            $color = $colors[1 + ($i % ($colors.Count - 1))]
            $points = New-PolygonPoints $Random ($Random.Next(128)) ($Random.Next(128)) 12 34 (5 + $Random.Next(4))
            Fill-WrappedPolygon $Graphics $color $points 128
        }
        for ($i = 0; $i -lt 10; $i++) {
            $color = $colors[1 + $Random.Next($colors.Count - 1)]
            Fill-WrappedEllipse $Graphics $color ($Random.Next(128)) ($Random.Next(128)) (18 + $Random.Next(26)) (12 + $Random.Next(20)) 128
        }
    }
}

function Draw-SplinterPattern([System.Drawing.Bitmap]$Bitmap, [hashtable]$Family, [System.Random]$Random) {
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($colors[0])
        for ($i = 0; $i -lt 20; $i++) {
            $color = $colors[1 + ($i % ($colors.Count - 1))]
            $x = $Random.Next(128)
            $y = $Random.Next(128)
            $width = 22 + $Random.Next(34)
            $height = 8 + $Random.Next(14)
            $points = @(
                [System.Drawing.PointF]::new($x, $y),
                [System.Drawing.PointF]::new($x + $width, $y + (2 + $Random.Next(5))),
                [System.Drawing.PointF]::new($x + $width - (4 + $Random.Next(8)), $y + $height),
                [System.Drawing.PointF]::new($x - (3 + $Random.Next(6)), $y + $height - (2 + $Random.Next(4)))
            )
            Fill-WrappedPolygon $Graphics $color $points 128
        }
        for ($i = 0; $i -lt 10; $i++) {
            $strokeColor = Mix-Color $colors[2] $colors[3] 0.55
            Fill-WrappedLine $Graphics $strokeColor ($Random.Next(128)) ($Random.Next(128)) ($Random.Next(128)) ($Random.Next(128)) (3 + $Random.Next(3)) 128
        }
    }
}

function Draw-DigitalPattern([System.Drawing.Bitmap]$Bitmap, [hashtable]$Family, [System.Random]$Random) {
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($colors[0])
        for ($i = 0; $i -lt 90; $i++) {
            $grid = if ($Random.NextDouble() -lt 0.45) { 4 } else { 8 }
            $x = ($Random.Next([int](128 / $grid)) * $grid)
            $y = ($Random.Next([int](128 / $grid)) * $grid)
            $width = (2 + $Random.Next(7)) * $grid
            $height = (2 + $Random.Next(6)) * $grid
            $color = $colors[1 + $Random.Next($colors.Count - 1)]
            Fill-WrappedRect $Graphics $color $x $y $width $height 128
        }
        for ($i = 0; $i -lt 140; $i++) {
            $grid = 4
            $x = ($Random.Next(32) * $grid)
            $y = ($Random.Next(32) * $grid)
            $size = (1 + $Random.Next(2)) * $grid
            $color = $colors[1 + $Random.Next($colors.Count - 1)]
            Fill-WrappedRect $Graphics $color $x $y $size $size 128
        }
    }
}

function Draw-WinterPattern([System.Drawing.Bitmap]$Bitmap, [hashtable]$Family, [System.Random]$Random) {
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($colors[0])
        for ($i = 0; $i -lt 10; $i++) {
            $x = $Random.Next(-20, 100)
            $y = $Random.Next(128)
            $width = 52 + $Random.Next(38)
            $points = @(
                [System.Drawing.PointF]::new($x, $y),
                [System.Drawing.PointF]::new($x + $width, $y - (8 + $Random.Next(8))),
                [System.Drawing.PointF]::new($x + $width + (12 + $Random.Next(10)), $y + (6 + $Random.Next(12))),
                [System.Drawing.PointF]::new($x + (6 + $Random.Next(10)), $y + (18 + $Random.Next(12)))
            )
            Fill-WrappedPolygon $Graphics $colors[1 + ($i % ($colors.Count - 1))] $points 128
        }
        for ($i = 0; $i -lt 20; $i++) {
            $color = Mix-Color $colors[0] $colors[2] (0.18 + ($Random.NextDouble() * 0.12))
            Fill-WrappedEllipse $Graphics $color ($Random.Next(128)) ($Random.Next(128)) (10 + $Random.Next(24)) (6 + $Random.Next(12)) 128
        }
    }
}

function Draw-NightPattern([System.Drawing.Bitmap]$Bitmap, [hashtable]$Family, [System.Random]$Random) {
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($colors[0])
        for ($i = 0; $i -lt 24; $i++) {
            $color = $colors[1 + $Random.Next($colors.Count - 1)]
            $points = New-PolygonPoints $Random ($Random.Next(128)) ($Random.Next(128)) 10 28 (4 + $Random.Next(4))
            Fill-WrappedPolygon $Graphics $color $points 128
        }
        for ($i = 0; $i -lt 36; $i++) {
            $color = Mix-Color $colors[1] $colors[3] (0.55 + ($Random.NextDouble() * 0.25))
            Fill-WrappedRect $Graphics $color ($Random.Next(128)) ($Random.Next(128)) (4 + $Random.Next(16)) (4 + $Random.Next(16)) 128
        }
    }
}

function Draw-SolidPattern([System.Drawing.Bitmap]$Bitmap, [hashtable]$Family, [System.Random]$Random) {
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($colors[0])
        for ($i = 0; $i -lt 6; $i++) {
            $shade = Mix-Color $colors[0] $colors[1 + ($i % ($colors.Count - 1))] (0.14 + ($Random.NextDouble() * 0.12))
            $x = ($i % 3) * 42
            $y = [int][Math]::Floor($i / 3) * 60
            Fill-WrappedRect $Graphics $shade ($x + $Random.Next(-4, 5)) ($y + $Random.Next(-4, 5)) (34 + $Random.Next(20)) (26 + $Random.Next(24)) 128
        }
        for ($i = 0; $i -lt 8; $i++) {
            $lineColor = Mix-Color $colors[2] $colors[3] 0.55
            Fill-WrappedLine $Graphics $lineColor ($Random.Next(128)) ($Random.Next(128)) ($Random.Next(128)) ($Random.Next(128)) 2.0 128
        }
        for ($i = 0; $i -lt 10; $i++) {
            $dotColor = Mix-Color $colors[2] $colors[3] 0.25
            Fill-WrappedEllipse $Graphics $dotColor ($Random.Next(128)) ($Random.Next(128)) 3 3 128
        }
    }
}

function New-MasterTile([hashtable]$Family) {
    $bitmap = New-Bitmap 128 128
    $random = New-Random ("master/" + $Family.Id)
    switch ($Family.Type) {
        "digital" { Draw-DigitalPattern $bitmap $Family $random }
        "splinter" { Draw-SplinterPattern $bitmap $Family $random }
        "winter" { Draw-WinterPattern $bitmap $Family $random }
        "night" { Draw-NightPattern $bitmap $Family $random }
        "solid" { Draw-SolidPattern $bitmap $Family $random }
        default { Draw-MacroPattern $bitmap $Family $random }
    }
    return $bitmap
}

function Apply-VariantDetails([System.Drawing.Bitmap]$Bitmap, [hashtable]$Family, [hashtable]$Variant) {
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }
    $random = New-Random ("variant/" + $Family.Id + "/" + $Variant.Id)
    Use-Graphics $Bitmap {
        param($Graphics)
        $clip = [System.Drawing.Rectangle]::new(10, 10, 108, 108)
        $Graphics.SetClip($clip)
        if ($Family.Type -eq "solid") {
            $panelColor = Mix-Color $colors[1] $colors[2] (0.2 + ($random.NextDouble() * 0.18))
            for ($i = 0; $i -lt 6; $i++) {
                Fill-WrappedRect $Graphics $panelColor ($random.Next(96) + 10) ($random.Next(96) + 10) (20 + $random.Next(28)) (10 + $random.Next(18)) 128
            }
            if ($Variant.Id -eq "b") {
                for ($i = 0; $i -lt 3; $i++) {
                    $lineColor = Mix-Color $colors[2] $colors[3] 0.4
                    Fill-WrappedLine $Graphics $lineColor (16 + ($i * 28)) 14 (18 + ($i * 28)) 114 2.0 128
                }
            }
            if ($Variant.Id -eq "c") {
                for ($i = 0; $i -lt 14; $i++) {
                    $spotColor = Mix-Color $colors[1] $colors[3] 0.18
                    Fill-WrappedEllipse $Graphics $spotColor ($random.Next(100) + 14) ($random.Next(100) + 14) (6 + $random.Next(8)) (4 + $random.Next(6)) 128
                }
            }
        }
        else {
            for ($i = 0; $i -lt 9; $i++) {
                $accentColor = $colors[1 + $random.Next($colors.Count - 1)]
                if ($Family.Type -eq "digital") {
                    $grid = 4
                    Fill-WrappedRect $Graphics $accentColor (($random.Next(25) * $grid) + 8) (($random.Next(25) * $grid) + 8) ((2 + $random.Next(3)) * $grid) ((1 + $random.Next(3)) * $grid) 128
                }
                else {
                    $points = New-PolygonPoints $random ($random.Next(96) + 16) ($random.Next(96) + 16) 6 16 (4 + $random.Next(3))
                    Fill-WrappedPolygon $Graphics $accentColor $points 128
                }
            }
            if ($Variant.Id -eq "b") {
                for ($i = 0; $i -lt 3; $i++) {
                    $panelColor = Mix-Color $colors[2] $colors[3] 0.32
                    Fill-WrappedLine $Graphics $panelColor (18 + ($i * 30)) 12 (20 + ($i * 30)) 116 1.6 128
                }
            }
            if ($Variant.Id -eq "c") {
                for ($i = 0; $i -lt 11; $i++) {
                    $agedColor = Mix-Color $colors[0] $colors[3] 0.12
                    Fill-WrappedEllipse $Graphics $agedColor ($random.Next(100) + 14) ($random.Next(100) + 14) (6 + $random.Next(10)) (4 + $random.Next(8)) 128
                }
            }
        }
        $Graphics.ResetClip()
    }
}

function Apply-StateDetails([System.Drawing.Bitmap]$Bitmap, [hashtable]$Family, [int]$Mask) {
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }
    $random = New-Random ("state/" + $Family.Id + "/" + $Mask)
    Use-Graphics $Bitmap {
        param($Graphics)
        $clip = [System.Drawing.Rectangle]::new(8, 8, 112, 112)
        $Graphics.SetClip($clip)
        $edgeColor = Mix-Color $colors[1] $colors[-1] 0.28
        if ($Mask -band 1) { Fill-WrappedRect $Graphics $edgeColor (18 + $random.Next(40)) 12 (36 + $random.Next(18)) (8 + $random.Next(8)) 128 }
        if ($Mask -band 2) { Fill-WrappedRect $Graphics $edgeColor 92 (18 + $random.Next(40)) (8 + $random.Next(8)) (36 + $random.Next(18)) 128 }
        if ($Mask -band 4) { Fill-WrappedRect $Graphics $edgeColor (18 + $random.Next(40)) 92 (36 + $random.Next(18)) (8 + $random.Next(8)) 128 }
        if ($Mask -band 8) { Fill-WrappedRect $Graphics $edgeColor 12 (18 + $random.Next(40)) (8 + $random.Next(8)) (36 + $random.Next(18)) 128 }
        $centerColor = Mix-Color $colors[0] $colors[2] (0.08 + ($random.NextDouble() * 0.08))
        if ($Family.Type -eq "digital") {
            for ($i = 0; $i -lt 5; $i++) {
                Fill-WrappedRect $Graphics $centerColor (($random.Next(20) * 4) + 20) (($random.Next(20) * 4) + 20) ((1 + $random.Next(2)) * 4) ((1 + $random.Next(2)) * 4) 128
            }
        }
        else {
            for ($i = 0; $i -lt 3; $i++) {
                Fill-WrappedEllipse $Graphics $centerColor ($random.Next(72) + 24) ($random.Next(72) + 24) (10 + $random.Next(12)) (6 + $random.Next(10)) 128
            }
        }
        $Graphics.ResetClip()
    }
}

function Save-Bitmap([System.Drawing.Bitmap]$Bitmap, [string]$Path) {
    Ensure-Directory (Split-Path -Parent $Path)
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Write-Utf8File([string]$Path, [string]$Content) {
    Ensure-Directory (Split-Path -Parent $Path)
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Write-JsonFile([string]$Path, $Object) {
    $json = $Object | ConvertTo-Json -Depth 20
    Write-Utf8File $Path ($json + "`n")
}

Reset-Directory (Join-Path $assetsRoot "blockstates")
Reset-Directory (Join-Path $assetsRoot "models\block")
Reset-Directory (Join-Path $assetsRoot "models\item")
Reset-Directory (Join-Path $assetsRoot "textures\block")
Reset-Directory (Join-Path $assetsRoot "lang")
Reset-Directory (Join-Path $resourcesRoot "data\camowarfare")
Reset-Directory (Join-Path $resourcesRoot "data\minecraft")

$zhLang = [ordered]@{
    "itemGroup.camowarfare.camouflage_warfare" = "Camouflage Warfare"
}
$enLang = [ordered]@{
    "itemGroup.camowarfare.camouflage_warfare" = "Camouflage Warfare"
}

$allBlockIds = New-Object System.Collections.Generic.List[string]

foreach ($family in $families) {
    $masterTile = New-MasterTile $family
    foreach ($variant in $variants) {
        $variantTile = New-ClippedClone $masterTile
        Apply-VariantDetails $variantTile $family $variant
        $atlas = New-Bitmap 512 512
        Use-Graphics $atlas {
            param($Graphics)
            for ($mask = 0; $mask -lt 16; $mask++) {
                $tile = New-ClippedClone $variantTile
                Apply-StateDetails $tile $family $mask
                $column = $mask % 4
                $row = [int][Math]::Floor($mask / 4)
                $Graphics.DrawImage($tile, [System.Drawing.Rectangle]::new($column * 128, $row * 128, 128, 128))
                $tile.Dispose()
            }
        }
        $texturePath = Join-Path $assetsRoot ("textures\block\" + $family.Id + "\" + $variant.Id + ".png")
        Save-Bitmap $atlas $texturePath
        $samplePath = Join-Path $assetsRoot ("textures\block\" + $family.Id + "\" + $variant.Id + "_atlas.png")
        Save-Bitmap $variantTile $samplePath
        $atlas.Dispose()
        $variantTile.Dispose()
        $blockId = $family.Id + "_" + $variant.Id + "_block"
        $allBlockIds.Add($blockId)
        $zhLang["block.camowarfare.$blockId"] = "$($family.Zh)闂佸搫鍊婚幊鎾愁�?$($variant.Label)"
        $enLang["block.camowarfare.$blockId"] = "$($family.En) Block $($variant.Label)"
        $textureRef = "camowarfare:block/$($family.Id)/$($variant.Id)"
        $sampleRef = "camowarfare:block/$($family.Id)/$($variant.Id)_atlas"
        $blockModel = @"
{
  "parent": "minecraft:block/block",
  "render_type": "minecraft:solid",
  "loader": "camowarfare:connected_camo",
  "textures": {
    "atlas": "$textureRef",
    "particle": "$sampleRef"
  }
}
"@
        Write-Utf8File (Join-Path $assetsRoot ("models\block\" + $blockId + ".json")) $blockModel
        $itemModel = @"
{
  "parent": "minecraft:block/block",
  "render_type": "minecraft:solid",
  "loader": "camowarfare:connected_camo",
  "item_render": true,
  "textures": {
    "atlas": "$textureRef",
    "particle": "$sampleRef"
  }
}
"@
        Write-Utf8File (Join-Path $assetsRoot ("models\item\" + $blockId + ".json")) $itemModel
        $blockState = @"
{
  "multipart": [
    {
      "apply": {
        "model": "camowarfare:block/$blockId"
      }
    }
  ]
}
"@
        Write-Utf8File (Join-Path $assetsRoot ("blockstates\" + $blockId + ".json")) $blockState
        $lootTable = [ordered]@{
            type = "minecraft:block"
            pools = @([ordered]@{
                rolls = 1.0
                bonus_rolls = 0.0
                entries = @([ordered]@{ type = "minecraft:item"; name = "camowarfare:$blockId" })
                conditions = @([ordered]@{ condition = "minecraft:survives_explosion" })
            })
        }
        Write-JsonFile (Join-Path $resourcesRoot ("data\camowarfare\loot_tables\blocks\" + $blockId + ".json")) $lootTable
    }
    $masterTile.Dispose()
    if ($family.Legacy) {
        $allBlockIds.Add($family.Legacy)
        $zhLang["block.camowarfare.$($family.Legacy)"] = "$($family.Zh) Block (Legacy Compatibility)"
        $enLang["block.camowarfare.$($family.Legacy)"] = "$($family.En) Block (Legacy Compatibility)"
        $legacyTextureRef = "camowarfare:block/$($family.Id)/a"
        $legacySampleRef = "camowarfare:block/$($family.Id)/a_atlas"
        $legacyBlockModel = @"
{
  "parent": "minecraft:block/block",
  "render_type": "minecraft:solid",
  "loader": "camowarfare:connected_camo",
  "textures": {
    "atlas": "$legacyTextureRef",
    "particle": "$legacySampleRef"
  }
}
"@
        Write-Utf8File (Join-Path $assetsRoot ("models\block\" + $family.Legacy + ".json")) $legacyBlockModel
        $legacyItemModel = @"
{
  "parent": "minecraft:block/block",
  "render_type": "minecraft:solid",
  "loader": "camowarfare:connected_camo",
  "item_render": true,
  "textures": {
    "atlas": "$legacyTextureRef",
    "particle": "$legacySampleRef"
  }
}
"@
        Write-Utf8File (Join-Path $assetsRoot ("models\item\" + $family.Legacy + ".json")) $legacyItemModel
        $legacyState = @"
{
  "multipart": [
    {
      "apply": {
        "model": "camowarfare:block/$($family.Legacy)"
      }
    }
  ]
}
"@
        Write-Utf8File (Join-Path $assetsRoot ("blockstates\" + $family.Legacy + ".json")) $legacyState
        $legacyLootTable = [ordered]@{
            type = "minecraft:block"
            pools = @([ordered]@{
                rolls = 1.0
                bonus_rolls = 0.0
                entries = @([ordered]@{ type = "minecraft:item"; name = "camowarfare:$($family.Legacy)" })
                conditions = @([ordered]@{ condition = "minecraft:survives_explosion" })
            })
        }
        Write-JsonFile (Join-Path $resourcesRoot ("data\camowarfare\loot_tables\blocks\" + $family.Legacy + ".json")) $legacyLootTable
    }
}

Write-JsonFile (Join-Path $assetsRoot "lang\zh_cn.json") $zhLang
Write-JsonFile (Join-Path $assetsRoot "lang\en_us.json") $enLang
$pickaxeTag = [ordered]@{ replace = $false; values = @($allBlockIds | ForEach-Object { "camowarfare:$_" }) }
Write-JsonFile (Join-Path $resourcesRoot "data\minecraft\tags\block\mineable\pickaxe.json") $pickaxeTag
