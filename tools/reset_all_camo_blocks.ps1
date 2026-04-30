$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$resourcesRoot = Join-Path $projectRoot "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"
$texturesRoot = Join-Path $assetsRoot "textures\block"
$blockstatesRoot = Join-Path $assetsRoot "blockstates"
$blockModelsRoot = Join-Path $assetsRoot "models\block"
$itemModelsRoot = Join-Path $assetsRoot "models\item"
$langRoot = Join-Path $assetsRoot "lang"
$lootRoot = Join-Path $resourcesRoot "data\camowarfare\loot_tables\blocks"
$pickaxeTagPath = Join-Path $resourcesRoot "data\minecraft\tags\block\mineable\pickaxe.json"

$variants = @(
    [ordered]@{ Id = "a"; Suffix = "A" },
    [ordered]@{ Id = "b"; Suffix = "B" },
    [ordered]@{ Id = "c"; Suffix = "C" },
    [ordered]@{ Id = "d"; Suffix = "D" }
)

$families = @(
    [ordered]@{ Id = "nato_woodland"; Zh = "Woodland Blotch"; En = "Woodland Blotch"; Legacy = "nato_woodland_block"; Mode = "macro"; Palette = @("#59624A", "#73815D", "#705E43", "#303528", "#9AA982") },
    [ordered]@{ Id = "nato_woodland_riveted"; Zh = "Woodland Blotch Riveted"; En = "Woodland Blotch Riveted"; Legacy = $null; Mode = "macro"; Overlay = "riveted"; Palette = @("#59624A", "#73815D", "#705E43", "#303528", "#9AA982") },
    [ordered]@{ Id = "nato_woodland_stained"; Zh = "Woodland Blotch Stained"; En = "Woodland Blotch Stained"; Legacy = $null; Mode = "macro"; Overlay = "stained"; Palette = @("#59624A", "#73815D", "#705E43", "#303528", "#9AA982") },
    [ordered]@{ Id = "nato_woodland_weathered"; Zh = "Woodland Blotch Weathered"; En = "Woodland Blotch Weathered"; Legacy = $null; Mode = "macro"; Overlay = "weathered"; Palette = @("#59624A", "#73815D", "#705E43", "#303528", "#9AA982") },
    [ordered]@{ Id = "woodland_macro"; Zh = "Wide Woodland"; En = "Wide Woodland"; Legacy = $null; Mode = "macro"; Palette = @("#59624A", "#7A8567", "#7A694C", "#2E3528", "#A4AF89") },
    [ordered]@{ Id = "russian_green_splinter"; Zh = "Deep Green Splinter"; En = "Deep Green Splinter"; Legacy = "russian_green_splinter_block"; Mode = "splinter"; Palette = @("#566040", "#6B7852", "#445030", "#262D21", "#85936A") },
    [ordered]@{ Id = "russian_desert"; Zh = "Sand Splinter"; En = "Sand Splinter"; Legacy = "russian_desert_block"; Mode = "splinter"; Palette = @("#A18A63", "#B79E77", "#7F6747", "#5E4A33", "#D0B88F") },
    [ordered]@{ Id = "nato_desert"; Zh = "Desert Blotch"; En = "Desert Blotch"; Legacy = "nato_desert_block"; Mode = "macro"; Palette = @("#AA936A", "#C4AD83", "#8C724E", "#635136", "#D5C096") },
    [ordered]@{ Id = "nato_desert_riveted"; Zh = "Desert Blotch Riveted"; En = "Desert Blotch Riveted"; Legacy = $null; Mode = "macro"; Overlay = "riveted"; Palette = @("#AA936A", "#C4AD83", "#8C724E", "#635136", "#D5C096") },
    [ordered]@{ Id = "nato_desert_stained"; Zh = "Desert Blotch Stained"; En = "Desert Blotch Stained"; Legacy = $null; Mode = "macro"; Overlay = "stained"; Palette = @("#AA936A", "#C4AD83", "#8C724E", "#635136", "#D5C096") },
    [ordered]@{ Id = "nato_desert_weathered"; Zh = "Desert Blotch Weathered"; En = "Desert Blotch Weathered"; Legacy = $null; Mode = "macro"; Overlay = "weathered"; Palette = @("#AA936A", "#C4AD83", "#8C724E", "#635136", "#D5C096") },
    [ordered]@{ Id = "woodland_digital"; Zh = "Woodland Digital"; En = "Woodland Digital"; Legacy = "woodland_digital_block"; Mode = "digital"; Palette = @("#586346", "#72805B", "#404A32", "#23281E", "#8D9C73") },
    [ordered]@{ Id = "desert_digital"; Zh = "Desert Digital"; En = "Desert Digital"; Legacy = "desert_digital_block"; Mode = "digital"; Palette = @("#B7A078", "#D2BD96", "#967753", "#6C5238", "#E3D1AE") },
    [ordered]@{ Id = "urban_digital"; Zh = "Urban Digital"; En = "Urban Digital"; Legacy = "urban_digital_block"; Mode = "digital"; Palette = @("#7A8288", "#A0A8AD", "#5A6166", "#31363A", "#C2C8CB") },
    [ordered]@{ Id = "naval_bluegray"; Zh = "Naval Blue-Gray"; En = "Naval Blue-Gray"; Legacy = "naval_bluegray_block"; Mode = "macro"; Palette = @("#5E6C78", "#7C8C98", "#44515C", "#293039", "#A4B0BA") },
    [ordered]@{ Id = "winter_whitewash"; Zh = "Winter Whitewash"; En = "Winter Whitewash"; Legacy = "winter_whitewash_block"; Mode = "winter"; Palette = @("#E8EAE7", "#D2D7D7", "#A3A79E", "#6E7567", "#C4CCBD") },
    [ordered]@{ Id = "black_night"; Zh = "Night Pattern"; En = "Night Pattern"; Legacy = "black_night_block"; Mode = "night"; Palette = @("#17191C", "#2A2E32", "#3A4045", "#0D0F11", "#5A6268") },
    [ordered]@{ Id = "solid_military_green"; Zh = "Military Green"; En = "Military Green"; Legacy = $null; Mode = "solid"; Palette = @("#5C6848", "#6B7855", "#4B563A", "#37412C", "#80906A") },
    [ordered]@{ Id = "solid_desert_sand"; Zh = "Desert Sand"; En = "Desert Sand"; Legacy = $null; Mode = "solid"; Palette = @("#B09768", "#C3AA7D", "#957B51", "#705838", "#D7C095") },
    [ordered]@{ Id = "solid_bluegray"; Zh = "Blue-Gray"; En = "Blue-Gray"; Legacy = $null; Mode = "solid"; Palette = @("#65727D", "#7E8C95", "#4E5962", "#333C43", "#A4B0B7") },
    [ordered]@{ Id = "solid_night_black"; Zh = "Night Black"; En = "Night Black"; Legacy = $null; Mode = "solid"; Palette = @("#22262A", "#31373B", "#191D20", "#101214", "#4A535A") },
    [ordered]@{ Id = "stryker_deep_olive"; Zh = "Deep Armor Green"; En = "Deep Armor Green"; Legacy = $null; Mode = "solid"; Palette = @("#465038", "#576347", "#394130", "#252B1F", "#6F7B5E") },
    [ordered]@{ Id = "stryker_deep_olive_riveted"; Zh = "Deep Armor Green Riveted"; En = "Deep Armor Green Riveted"; Legacy = $null; Mode = "solid"; Overlay = "riveted"; Palette = @("#465038", "#576347", "#394130", "#252B1F", "#6F7B5E") },
    [ordered]@{ Id = "stryker_deep_olive_stained"; Zh = "Deep Armor Green Stained"; En = "Deep Armor Green Stained"; Legacy = $null; Mode = "solid"; Overlay = "stained"; Palette = @("#465038", "#576347", "#394130", "#252B1F", "#6F7B5E") },
    [ordered]@{ Id = "stryker_deep_olive_weathered"; Zh = "Deep Armor Green Weathered"; En = "Deep Armor Green Weathered"; Legacy = $null; Mode = "solid"; Overlay = "weathered"; Palette = @("#465038", "#576347", "#394130", "#252B1F", "#6F7B5E") },
    [ordered]@{ Id = "pla_05_naval_blue"; Zh = "Deep Naval Blue"; En = "Deep Naval Blue"; Legacy = $null; Mode = "solid"; Palette = @("#31465C", "#425B73", "#28384A", "#19222C", "#627C92") },
    [ordered]@{ Id = "pla_05_naval_blue_riveted"; Zh = "Deep Naval Blue Riveted"; En = "Deep Naval Blue Riveted"; Legacy = $null; Mode = "solid"; Overlay = "riveted"; Palette = @("#31465C", "#425B73", "#28384A", "#19222C", "#627C92") },
    [ordered]@{ Id = "pla_05_naval_blue_stained"; Zh = "Deep Naval Blue Stained"; En = "Deep Naval Blue Stained"; Legacy = $null; Mode = "solid"; Overlay = "stained"; Palette = @("#31465C", "#425B73", "#28384A", "#19222C", "#627C92") },
    [ordered]@{ Id = "pla_05_naval_blue_weathered"; Zh = "Deep Naval Blue Weathered"; En = "Deep Naval Blue Weathered"; Legacy = $null; Mode = "solid"; Overlay = "weathered"; Palette = @("#31465C", "#425B73", "#28384A", "#19222C", "#627C92") },
    [ordered]@{ Id = "ukrainian_yellow_green"; Zh = "Yellow-Green Mixed Camo"; En = "Yellow-Green Mixed Camo"; Legacy = $null; Mode = "macro"; Palette = @("#717941", "#9A9250", "#556131", "#3C4125", "#B9AC67") },
    [ordered]@{ Id = "ukrainian_yellow_green_riveted"; Zh = "Yellow-Green Mixed Camo Riveted"; En = "Yellow-Green Mixed Camo Riveted"; Legacy = $null; Mode = "macro"; Overlay = "riveted"; Palette = @("#717941", "#9A9250", "#556131", "#3C4125", "#B9AC67") },
    [ordered]@{ Id = "ukrainian_yellow_green_stained"; Zh = "Yellow-Green Mixed Camo Stained"; En = "Yellow-Green Mixed Camo Stained"; Legacy = $null; Mode = "macro"; Overlay = "stained"; Palette = @("#717941", "#9A9250", "#556131", "#3C4125", "#B9AC67") },
    [ordered]@{ Id = "ukrainian_yellow_green_weathered"; Zh = "Yellow-Green Mixed Camo Weathered"; En = "Yellow-Green Mixed Camo Weathered"; Legacy = $null; Mode = "macro"; Overlay = "weathered"; Palette = @("#717941", "#9A9250", "#556131", "#3C4125", "#B9AC67") },
    [ordered]@{ Id = "pla_woodland"; Zh = "Woodland Patch"; En = "Woodland Patch"; Legacy = $null; Mode = "macro"; Palette = @("#5D6548", "#7C7E59", "#786448", "#303426", "#96A274") },
    [ordered]@{ Id = "pla_woodland_riveted"; Zh = "Woodland Patch Riveted"; En = "Woodland Patch Riveted"; Legacy = $null; Mode = "macro"; Overlay = "riveted"; Palette = @("#5D6548", "#7C7E59", "#786448", "#303426", "#96A274") },
    [ordered]@{ Id = "pla_woodland_stained"; Zh = "Woodland Patch Stained"; En = "Woodland Patch Stained"; Legacy = $null; Mode = "macro"; Overlay = "stained"; Palette = @("#5D6548", "#7C7E59", "#786448", "#303426", "#96A274") },
    [ordered]@{ Id = "pla_woodland_weathered"; Zh = "Woodland Patch Weathered"; En = "Woodland Patch Weathered"; Legacy = $null; Mode = "macro"; Overlay = "weathered"; Palette = @("#5D6548", "#7C7E59", "#786448", "#303426", "#96A274") },
    [ordered]@{ Id = "pla_mountain"; Zh = "Mountain Patch"; En = "Mountain Patch"; Legacy = $null; Mode = "macro"; Palette = @("#6A6C58", "#8A8467", "#7A6652", "#424236", "#A4A085") },
    [ordered]@{ Id = "pla_mountain_riveted"; Zh = "Mountain Patch Riveted"; En = "Mountain Patch Riveted"; Legacy = $null; Mode = "macro"; Overlay = "riveted"; Palette = @("#6A6C58", "#8A8467", "#7A6652", "#424236", "#A4A085") },
    [ordered]@{ Id = "pla_mountain_stained"; Zh = "Mountain Patch Stained"; En = "Mountain Patch Stained"; Legacy = $null; Mode = "macro"; Overlay = "stained"; Palette = @("#6A6C58", "#8A8467", "#7A6652", "#424236", "#A4A085") },
    [ordered]@{ Id = "pla_mountain_weathered"; Zh = "Mountain Patch Weathered"; En = "Mountain Patch Weathered"; Legacy = $null; Mode = "macro"; Overlay = "weathered"; Palette = @("#6A6C58", "#8A8467", "#7A6652", "#424236", "#A4A085") },
    [ordered]@{ Id = "woodland_macro_riveted"; Zh = "Wide Woodland Riveted"; En = "Wide Woodland Riveted"; Legacy = $null; Mode = "macro"; Overlay = "riveted"; Palette = @("#59624A", "#7A8567", "#7A694C", "#2E3528", "#A4AF89") },
    [ordered]@{ Id = "woodland_macro_stained"; Zh = "Wide Woodland Stained"; En = "Wide Woodland Stained"; Legacy = $null; Mode = "macro"; Overlay = "stained"; Palette = @("#59624A", "#7A8567", "#7A694C", "#2E3528", "#A4AF89") },
    [ordered]@{ Id = "woodland_macro_weathered"; Zh = "Wide Woodland Weathered"; En = "Wide Woodland Weathered"; Legacy = $null; Mode = "macro"; Overlay = "weathered"; Palette = @("#59624A", "#7A8567", "#7A694C", "#2E3528", "#A4AF89") }
)

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Write-Utf8File([string]$Path, [string]$Content) {
    Ensure-Directory (Split-Path -Parent $Path)
    $utf8 = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Write-JsonFile([string]$Path, $Object) {
    Write-Utf8File $Path (($Object | ConvertTo-Json -Depth 20) + "`n")
}

function New-Random([string]$SeedText) {
    return [System.Random]::new([Math]::Abs($SeedText.GetHashCode()))
}

function New-Bitmap([int]$Width, [int]$Height) {
    return [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function Save-Png([System.Drawing.Bitmap]$Bitmap, [string]$Path) {
    if (Test-Path $Path) {
        Remove-Item -LiteralPath $Path -Force
    }
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
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

function Mix-Color([System.Drawing.Color]$A, [System.Drawing.Color]$B, [double]$WeightB) {
    $weightA = 1.0 - $WeightB
    return [System.Drawing.Color]::FromArgb(
        255,
        [Math]::Min(255, [Math]::Max(0, [int](($A.R * $weightA) + ($B.R * $WeightB)))),
        [Math]::Min(255, [Math]::Max(0, [int](($A.G * $weightA) + ($B.G * $WeightB)))),
        [Math]::Min(255, [Math]::Max(0, [int](($A.B * $weightA) + ($B.B * $WeightB))))
    )
}

function Shift-Points([System.Drawing.PointF[]]$Points, [float]$OffsetX, [float]$OffsetY) {
    $shifted = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
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

function New-IrregularPatch(
    [System.Random]$Random,
    [float]$CenterX,
    [float]$CenterY,
    [float]$RadiusX,
    [float]$RadiusY,
    [int]$PointCount
) {
    $points = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
    $angleOffset = $Random.NextDouble() * [Math]::PI * 2.0
    for ($index = 0; $index -lt $PointCount; $index++) {
        $angle = $angleOffset + (($index / [double]$PointCount) * [Math]::PI * 2.0)
        $jitterX = 0.72 + ($Random.NextDouble() * 0.38)
        $jitterY = 0.72 + ($Random.NextDouble() * 0.38)
        $x = $CenterX + ([Math]::Cos($angle) * $RadiusX * $jitterX)
        $y = $CenterY + ([Math]::Sin($angle) * $RadiusY * $jitterY)
        $points.Add([System.Drawing.PointF]::new([float]$x, [float]$y))
    }
    return $points.ToArray()
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

function Draw-MacroMaster([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Color[]]$Palette, [System.Random]$Random) {
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($Palette[0])
        foreach ($spec in @(
            @{ Color = $Palette[1]; Count = 5; RadiusMin = 46; RadiusMax = 84; AspectMin = 1.1; AspectMax = 1.9 },
            @{ Color = $Palette[2]; Count = 4; RadiusMin = 44; RadiusMax = 80; AspectMin = 1.1; AspectMax = 2.1 },
            @{ Color = $Palette[3]; Count = 4; RadiusMin = 42; RadiusMax = 78; AspectMin = 1.0; AspectMax = 2.2 },
            @{ Color = $Palette[4]; Count = 2; RadiusMin = 22; RadiusMax = 34; AspectMin = 1.0; AspectMax = 1.4 }
        )) {
            for ($i = 0; $i -lt $spec.Count; $i++) {
                $centerX = 24 + ($Random.NextDouble() * 208)
                $centerY = 24 + ($Random.NextDouble() * 208)
                $radius = $spec.RadiusMin + ($Random.NextDouble() * ($spec.RadiusMax - $spec.RadiusMin))
                $aspect = $spec.AspectMin + ($Random.NextDouble() * ($spec.AspectMax - $spec.AspectMin))
                if ($Random.NextDouble() -gt 0.5) {
                    $radiusX = $radius * $aspect
                    $radiusY = $radius
                }
                else {
                    $radiusX = $radius
                    $radiusY = $radius * $aspect
                }
                $points = New-IrregularPatch -Random $Random -CenterX $centerX -CenterY $centerY -RadiusX $radiusX -RadiusY $radiusY -PointCount (6 + $Random.Next(4))
                Fill-WrappedPolygon -Graphics $Graphics -Color $spec.Color -Points $points -TileSize 256
            }
        }
    }
}

function Draw-SplinterMaster([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Color[]]$Palette, [System.Random]$Random) {
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($Palette[0])
        for ($i = 0; $i -lt 11; $i++) {
            $color = $Palette[1 + ($i % 3)]
            $centerX = 18 + ($Random.NextDouble() * 220)
            $centerY = 18 + ($Random.NextDouble() * 220)
            $length = 84 + ($Random.NextDouble() * 90)
            $thickness = 18 + ($Random.NextDouble() * 28)
            $angle = $Random.NextDouble() * [Math]::PI
            $dx = [Math]::Cos($angle) * $length * 0.5
            $dy = [Math]::Sin($angle) * $length * 0.5
            $px = -[Math]::Sin($angle) * $thickness * 0.5
            $py = [Math]::Cos($angle) * $thickness * 0.5
            $points = @(
                [System.Drawing.PointF]::new([float]($centerX - $dx - $px), [float]($centerY - $dy - $py)),
                [System.Drawing.PointF]::new([float]($centerX + $dx - ($px * 0.4)), [float]($centerY + $dy - ($py * 0.4))),
                [System.Drawing.PointF]::new([float]($centerX + $dx + $px), [float]($centerY + $dy + $py)),
                [System.Drawing.PointF]::new([float]($centerX - $dx + ($px * 0.4)), [float]($centerY - $dy + ($py * 0.4)))
            )
            Fill-WrappedPolygon -Graphics $Graphics -Color $color -Points $points -TileSize 256
        }
    }
}

function Draw-DigitalMaster([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Color[]]$Palette, [System.Random]$Random) {
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($Palette[0])
        for ($i = 0; $i -lt 36; $i++) {
            $grid = if ($Random.NextDouble() -lt 0.65) { 16 } else { 8 }
            $x = ($Random.Next([int](256 / $grid)) * $grid)
            $y = ($Random.Next([int](256 / $grid)) * $grid)
            $width = (2 + $Random.Next(6)) * $grid
            $height = (2 + $Random.Next(5)) * $grid
            $color = $Palette[1 + $Random.Next(4)]
            Fill-WrappedRect -Graphics $Graphics -Color $color -X $x -Y $y -Width $width -Height $height -TileSize 256
        }
        for ($i = 0; $i -lt 18; $i++) {
            $x = ($Random.Next(32) * 8)
            $y = ($Random.Next(32) * 8)
            $width = (1 + $Random.Next(3)) * 8
            $height = (1 + $Random.Next(3)) * 8
            $color = $Palette[1 + $Random.Next(4)]
            Fill-WrappedRect -Graphics $Graphics -Color $color -X $x -Y $y -Width $width -Height $height -TileSize 256
        }
    }
}

function Draw-SolidMaster([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Color[]]$Palette, [System.Random]$Random) {
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($Palette[0])
        foreach ($index in 0..4) {
            $color = if ($index % 2 -eq 0) { Mix-Color $Palette[0] $Palette[1] 0.45 } else { Mix-Color $Palette[0] $Palette[3] 0.35 }
            $centerX = 28 + ($Random.NextDouble() * 200)
            $centerY = 28 + ($Random.NextDouble() * 200)
            $radius = 54 + ($Random.NextDouble() * 80)
            $points = New-IrregularPatch -Random $Random -CenterX $centerX -CenterY $centerY -RadiusX $radius -RadiusY ($radius * (0.8 + $Random.NextDouble() * 0.5)) -PointCount (5 + $Random.Next(3))
            Fill-WrappedPolygon -Graphics $Graphics -Color $color -Points $points -TileSize 256
        }
    }
}

function Draw-WinterMaster([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Color[]]$Palette, [System.Random]$Random) {
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($Palette[0])
        foreach ($index in 0..5) {
            $color = if ($index % 2 -eq 0) { $Palette[1] } else { $Palette[2] }
            $centerX = 24 + ($Random.NextDouble() * 210)
            $centerY = 24 + ($Random.NextDouble() * 210)
            $radiusX = 62 + ($Random.NextDouble() * 76)
            $radiusY = 18 + ($Random.NextDouble() * 20)
            $points = New-IrregularPatch -Random $Random -CenterX $centerX -CenterY $centerY -RadiusX $radiusX -RadiusY $radiusY -PointCount (6 + $Random.Next(3))
            Fill-WrappedPolygon -Graphics $Graphics -Color $color -Points $points -TileSize 256
        }
        foreach ($index in 0..2) {
            $centerX = 30 + ($Random.NextDouble() * 196)
            $centerY = 30 + ($Random.NextDouble() * 196)
            $points = New-IrregularPatch -Random $Random -CenterX $centerX -CenterY $centerY -RadiusX (24 + $Random.NextDouble() * 40) -RadiusY (20 + $Random.NextDouble() * 34) -PointCount (6 + $Random.Next(3))
            Fill-WrappedPolygon -Graphics $Graphics -Color $Palette[3] -Points $points -TileSize 256
        }
    }
}

function Add-RivetedOverlay([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Color[]]$Palette, [System.Random]$Random) {
    $lineColor = Mix-Color $Palette[0] $Palette[3] 0.48
    $rivetColor = Mix-Color $Palette[2] $Palette[4] 0.35
    $highlightColor = Mix-Color $Palette[1] $Palette[4] 0.26
    $weldColor = Mix-Color $Palette[0] $Palette[3] 0.58
    Use-Graphics $Bitmap {
        param($Graphics)
        foreach ($index in 0..2) {
            $x = 30 + ($Random.NextDouble() * 170)
            $y = 22 + ($Random.NextDouble() * 170)
            $height = 46 + $Random.Next(74)
            Fill-WrappedRect -Graphics $Graphics -Color $lineColor -X $x -Y $y -Width 2 -Height $height -TileSize 256
            Fill-WrappedRect -Graphics $Graphics -Color $highlightColor -X ($x + 2) -Y ($y + 2) -Width 1 -Height ([Math]::Max(18, $height - 8)) -TileSize 256
            foreach ($offset in 0..(3 + $Random.Next(2))) {
                $ry = $y + 6 + ($offset * 12)
                Fill-WrappedRect -Graphics $Graphics -Color $rivetColor -X ($x - 2) -Y $ry -Width 4 -Height 4 -TileSize 256
                Fill-WrappedRect -Graphics $Graphics -Color $highlightColor -X ($x - 1) -Y ($ry + 1) -Width 2 -Height 1 -TileSize 256
            }
        }
        foreach ($index in 0..1) {
            $y = 46 + ($Random.NextDouble() * 144)
            $x = 34 + ($Random.NextDouble() * 146)
            $width = 34 + $Random.Next(42)
            Fill-WrappedRect -Graphics $Graphics -Color $lineColor -X $x -Y $y -Width $width -Height 2 -TileSize 256
            foreach ($offset in 0..(2 + $Random.Next(2))) {
                $rx = $x + 8 + ($offset * 14)
                Fill-WrappedRect -Graphics $Graphics -Color $rivetColor -X $rx -Y ($y - 1) -Width 4 -Height 4 -TileSize 256
            }
        }
        foreach ($index in 0..2) {
            $x = 36 + ($Random.NextDouble() * 166)
            $y = 34 + ($Random.NextDouble() * 168)
            foreach ($dot in 0..(4 + $Random.Next(2))) {
                Fill-WrappedRect -Graphics $Graphics -Color $weldColor -X ($x + ($dot * 4)) -Y ($y + (($dot % 2) * 2)) -Width 2 -Height 2 -TileSize 256
            }
        }
    }
}

function Add-StainedOverlay([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Color[]]$Palette, [System.Random]$Random) {
    $stainDark = Mix-Color $Palette[0] $Palette[3] 0.34
    $stainMid = Mix-Color $Palette[1] $Palette[0] 0.42
    $stainEdge = Mix-Color $Palette[2] $Palette[3] 0.18
    Use-Graphics $Bitmap {
        param($Graphics)
        foreach ($index in 0..5) {
            $x = 24 + ($Random.NextDouble() * 186)
            $y = 18 + ($Random.NextDouble() * 170)
            $width = 12 + ($Random.NextDouble() * 18)
            $height = 28 + ($Random.NextDouble() * 42)
            Fill-WrappedRect -Graphics $Graphics -Color $stainMid -X $x -Y $y -Width $width -Height $height -TileSize 256
            Fill-WrappedRect -Graphics $Graphics -Color $stainDark -X ($x + ($width * 0.3)) -Y ($y + 5) -Width ([Math]::Max(4, $width * 0.34)) -Height ($height - 8) -TileSize 256
            if ($Random.NextDouble() -gt 0.35) {
                Fill-WrappedRect -Graphics $Graphics -Color $stainEdge -X ($x - 2) -Y ($y + 2) -Width 3 -Height ([Math]::Max(8, $height * 0.55)) -TileSize 256
            }
        }
        foreach ($index in 0..3) {
            $centerX = 42 + ($Random.NextDouble() * 170)
            $centerY = 40 + ($Random.NextDouble() * 160)
            $points = New-IrregularPatch -Random $Random -CenterX $centerX -CenterY $centerY -RadiusX (16 + $Random.NextDouble() * 22) -RadiusY (12 + $Random.NextDouble() * 18) -PointCount (5 + $Random.Next(3))
            Fill-WrappedPolygon -Graphics $Graphics -Color $stainDark -Points $points -TileSize 256
            if ($Random.NextDouble() -gt 0.4) {
                $dripX = $centerX + (-4 + $Random.NextDouble() * 8)
                $dripY = $centerY + 8
                Fill-WrappedRect -Graphics $Graphics -Color $stainMid -X $dripX -Y $dripY -Width 3 -Height (12 + $Random.Next(18)) -TileSize 256
            }
        }
    }
}

function Add-WeatheredOverlay([System.Drawing.Bitmap]$Bitmap, [System.Drawing.Color[]]$Palette, [System.Random]$Random) {
    $chipLight = Mix-Color $Palette[1] $Palette[4] 0.28
    $chipDark = Mix-Color $Palette[0] $Palette[3] 0.30
    Use-Graphics $Bitmap {
        param($Graphics)
        foreach ($index in 0..9) {
            $x = 18 + ($Random.NextDouble() * 212)
            $y = 18 + ($Random.NextDouble() * 212)
            $width = 5 + ($Random.NextDouble() * 12)
            $height = 2 + ($Random.NextDouble() * 5)
            Fill-WrappedRect -Graphics $Graphics -Color $chipLight -X $x -Y $y -Width $width -Height $height -TileSize 256
            if ($Random.NextDouble() -gt 0.45) {
                Fill-WrappedRect -Graphics $Graphics -Color $chipDark -X ($x + 1) -Y ($y + 1) -Width ([Math]::Max(2, $width - 2)) -Height 1 -TileSize 256
            }
        }
        foreach ($index in 0..5) {
            $x = 22 + ($Random.NextDouble() * 210)
            $y = 22 + ($Random.NextDouble() * 210)
            $width = 8 + ($Random.NextDouble() * 20)
            Fill-WrappedRect -Graphics $Graphics -Color $chipDark -X $x -Y $y -Width $width -Height 1 -TileSize 256
        }
    }
}

function Draw-FamilyMaster([hashtable]$Family) {
    $bitmap = New-Bitmap 256 256
    $palette = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }
    $random = New-Random $Family.Id
    switch ($Family.Mode) {
        "splinter" { Draw-SplinterMaster -Bitmap $bitmap -Palette $palette -Random $random }
        "digital" { Draw-DigitalMaster -Bitmap $bitmap -Palette $palette -Random $random }
        "solid" { Draw-SolidMaster -Bitmap $bitmap -Palette $palette -Random $random }
        "winter" { Draw-WinterMaster -Bitmap $bitmap -Palette $palette -Random $random }
        default { Draw-MacroMaster -Bitmap $bitmap -Palette $palette -Random $random }
    }
    if ($Family.Contains("Overlay")) {
        switch ($Family.Overlay) {
            "riveted" { Add-RivetedOverlay -Bitmap $bitmap -Palette $palette -Random $random }
            "stained" { Add-StainedOverlay -Bitmap $bitmap -Palette $palette -Random $random }
            "weathered" { Add-WeatheredOverlay -Bitmap $bitmap -Palette $palette -Random $random }
        }
    }
    return $bitmap
}

function New-Tile([System.Drawing.Bitmap]$Master, [int]$QuadrantX, [int]$QuadrantY) {
    $tile = New-Bitmap 128 128
    Copy-Rect -Source $Master -SourceX ($QuadrantX * 128) -SourceY ($QuadrantY * 128) -Width 128 -Height 128 -Target $tile -TargetX 0 -TargetY 0
    return $tile
}

function Write-BlockResources([hashtable]$Family, [hashtable]$Variant) {
    $blockName = "{0}_{1}_block" -f $Family.Id, $Variant.Id
    Write-JsonFile (Join-Path $blockstatesRoot ($blockName + ".json")) ([ordered]@{
        multipart = @(
            [ordered]@{
                apply = [ordered]@{
                    model = "camowarfare:block/$blockName"
                }
            }
        )
    })

    $model = [ordered]@{
        parent = "minecraft:block/cube_all"
        render_type = "minecraft:solid"
        textures = [ordered]@{
            all = "camowarfare:block/{0}/{1}_atlas" -f $Family.Id, $Variant.Id
            particle = "camowarfare:block/{0}/{1}_atlas" -f $Family.Id, $Variant.Id
        }
    }

    Write-JsonFile (Join-Path $blockModelsRoot ($blockName + ".json")) $model
    Write-JsonFile (Join-Path $blockModelsRoot ("{0}_{1}_appearance.json" -f $Family.Id, $Variant.Id)) $model
    Write-JsonFile (Join-Path $itemModelsRoot ($blockName + ".json")) ([ordered]@{ parent = "camowarfare:block/$blockName" })
    Write-JsonFile (Join-Path $lootRoot ($blockName + ".json")) ([ordered]@{
        type = "minecraft:block"
        pools = @(
            [ordered]@{
                rolls = 1
                entries = @(
                    [ordered]@{
                        type = "minecraft:item"
                        name = "camowarfare:$blockName"
                    }
                )
                conditions = @(
                    [ordered]@{
                        condition = "minecraft:survives_explosion"
                    }
                )
            }
        )
    })
}

Ensure-Directory $texturesRoot
Ensure-Directory $blockstatesRoot
Ensure-Directory $blockModelsRoot
Ensure-Directory $itemModelsRoot
Ensure-Directory $langRoot
Ensure-Directory $lootRoot

$zh = [ordered]@{
    "itemGroup.camowarfare.camouflage_warfare" = "Camouflage Warfare"
}
$en = [ordered]@{
    "itemGroup.camowarfare.camouflage_warfare" = "Camouflage Warfare"
}
$pickaxeValues = New-Object 'System.Collections.Generic.List[string]'

foreach ($family in $families) {
    $familyTextureRoot = Join-Path $texturesRoot $family.Id
    Ensure-Directory $familyTextureRoot

    $master = Draw-FamilyMaster $family
    try {
        foreach ($variant in $variants) {
            switch ($variant.Id) {
                "a" { $tile = New-Tile -Master $master -QuadrantX 0 -QuadrantY 0 }
                "b" { $tile = New-Tile -Master $master -QuadrantX 1 -QuadrantY 0 }
                "c" { $tile = New-Tile -Master $master -QuadrantX 0 -QuadrantY 1 }
                "d" { $tile = New-Tile -Master $master -QuadrantX 1 -QuadrantY 1 }
            }
            try {
                Save-Png -Bitmap $tile -Path (Join-Path $familyTextureRoot ($variant.Id + ".png"))
                Save-Png -Bitmap $tile -Path (Join-Path $familyTextureRoot ($variant.Id + "_atlas.png"))
            }
            finally {
                $tile.Dispose()
            }

            Write-BlockResources -Family $family -Variant $variant
            $blockKey = "block.camowarfare:" + $family.Id + "_" + $variant.Id + "_block"
            $blockKey = $blockKey.Replace(":", ".")
            $blockId = "camowarfare:" + $family.Id + "_" + $variant.Id + "_block"
            $zh[$blockKey] = "{0} Block {1}" -f $family.Zh, $variant.Suffix
            $en[$blockKey] = "{0} Block {1}" -f $family.En, $variant.Suffix
            $pickaxeValues.Add($blockId)
        }
    }
    finally {
        $master.Dispose()
    }

    if ($family.Legacy) {
        $zh["block.camowarfare.{0}" -f $family.Legacy] = "{0} Block (Legacy Compatibility)" -f $family.Zh
        $en["block.camowarfare.{0}" -f $family.Legacy] = "{0} Block (Legacy Compatibility)" -f $family.En
        $pickaxeValues.Add("camowarfare:{0}" -f $family.Legacy)
    }
}

Write-JsonFile (Join-Path $langRoot "zh_cn.json") $zh
Write-JsonFile (Join-Path $langRoot "en_us.json") $en
Write-JsonFile $pickaxeTagPath ([ordered]@{
    replace = $false
    values = $pickaxeValues
})
