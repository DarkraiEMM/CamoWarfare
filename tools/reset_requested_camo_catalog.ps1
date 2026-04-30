$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $root "src\main\resources\assets\camowarfare"
$dataRoot = Join-Path $root "src\main\resources\data"
$textureRoot = Join-Path $assetsRoot "textures\block"
$blockstateRoot = Join-Path $assetsRoot "blockstates"
$blockModelRoot = Join-Path $assetsRoot "models\block"
$itemModelRoot = Join-Path $assetsRoot "models\item"
$lootRoot = Join-Path $dataRoot "camowarfare\loot_tables\blocks"
$pickaxeTagPath = Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json"
$armoredTagPath = Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json"
$enLangPath = Join-Path $assetsRoot "lang\en_us.json"

function Ensure-Dir([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Assert-ChildPath([string]$Base, [string]$Path) {
    $baseResolved = [System.IO.Path]::GetFullPath($Base)
    $pathResolved = [System.IO.Path]::GetFullPath($Path)
    if (-not $pathResolved.StartsWith($baseResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to operate outside base path: $pathResolved"
    }
}

function Save-Json([string]$Path, $Data) {
    Ensure-Dir (Split-Path -Parent $Path)
    $json = $Data | ConvertTo-Json -Depth 24
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Load-Json([string]$Path) {
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function ConvertTo-Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function New-Bitmap([int]$Size, [string]$BaseHex) {
    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear((ConvertTo-Color $BaseHex))
    }
    finally {
        $graphics.Dispose()
    }
    return $bitmap
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
    $hash = [int64]2166136261
    foreach ($ch in $Seed.ToCharArray()) {
        $hash = ($hash -bxor [int64][char]$ch)
        $hash = ($hash * 16777619) % 4294967296
    }
    return [System.Random]::new([int]($hash -band 0x7FFFFFFF))
}

function Fill-WrappedPolygon($Graphics, [System.Drawing.Color]$Color, [System.Drawing.PointF[]]$Points, [int]$Size) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        foreach ($ox in @(-$Size, 0, $Size)) {
            foreach ($oy in @(-$Size, 0, $Size)) {
                $shifted = foreach ($point in $Points) {
                    [System.Drawing.PointF]::new($point.X + $ox, $point.Y + $oy)
                }
                $Graphics.FillPolygon($brush, $shifted)
            }
        }
    }
    finally {
        $brush.Dispose()
    }
}

function Fill-WrappedRect($Graphics, [System.Drawing.Color]$Color, [float]$X, [float]$Y, [float]$W, [float]$H, [int]$Size) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        foreach ($ox in @(-$Size, 0, $Size)) {
            foreach ($oy in @(-$Size, 0, $Size)) {
                $Graphics.FillRectangle($brush, $X + $ox, $Y + $oy, $W, $H)
            }
        }
    }
    finally {
        $brush.Dispose()
    }
}

function New-PatchPoints($Random, [float]$X, [float]$Y, [float]$W, [float]$H) {
    $left = $X
    $right = $X + $W
    $top = $Y
    $bottom = $Y + $H
    return @(
        [System.Drawing.PointF]::new($left + $Random.Next(0, 26), $top),
        [System.Drawing.PointF]::new($left + ($W * 0.52), $top + $Random.Next(-18, 18)),
        [System.Drawing.PointF]::new($right, $top + $Random.Next(10, 42)),
        [System.Drawing.PointF]::new($right - $Random.Next(0, 34), $top + ($H * 0.55)),
        [System.Drawing.PointF]::new($right - $Random.Next(8, 46), $bottom),
        [System.Drawing.PointF]::new($left + ($W * 0.35), $bottom + $Random.Next(-16, 16)),
        [System.Drawing.PointF]::new($left, $bottom - $Random.Next(12, 44)),
        [System.Drawing.PointF]::new($left + $Random.Next(0, 32), $top + ($H * 0.42))
    )
}

function Draw-MacroPattern([System.Drawing.Bitmap]$Bitmap, $Definition) {
    $random = New-SeedRandom $Definition.Id
    $colors = @($Definition.Palette | ForEach-Object { ConvertTo-Color $_ })
    Use-Graphics $Bitmap {
        param($Graphics)
        for ($i = 0; $i -lt 34; $i++) {
            $color = $colors[1 + ($i % ($colors.Count - 1))]
            $w = $random.Next(72, 170)
            $h = $random.Next(42, 116)
            $x = $random.Next(-60, 512)
            $y = $random.Next(-50, 512)
            Fill-WrappedPolygon $Graphics $color (New-PatchPoints $random $x $y $w $h) 512
        }
    }
}

function Draw-SplinterPattern([System.Drawing.Bitmap]$Bitmap, $Definition) {
    $random = New-SeedRandom $Definition.Id
    $colors = @($Definition.Palette | ForEach-Object { ConvertTo-Color $_ })
    Use-Graphics $Bitmap {
        param($Graphics)
        for ($band = -60; $band -lt 560; $band += $random.Next(42, 78)) {
            $height = $random.Next(16, 42)
            $color = $colors[1 + (($band + 512) % ($colors.Count - 1))]
            $points = @(
                [System.Drawing.PointF]::new(-64, $band + $random.Next(-18, 18)),
                [System.Drawing.PointF]::new(170, $band + $random.Next(-28, 30)),
                [System.Drawing.PointF]::new(352, $band + $random.Next(-28, 30)),
                [System.Drawing.PointF]::new(576, $band + $random.Next(-18, 18)),
                [System.Drawing.PointF]::new(576, $band + $height + $random.Next(-12, 16)),
                [System.Drawing.PointF]::new(356, $band + $height + $random.Next(-20, 24)),
                [System.Drawing.PointF]::new(160, $band + $height + $random.Next(-20, 24)),
                [System.Drawing.PointF]::new(-64, $band + $height + $random.Next(-12, 16))
            )
            Fill-WrappedPolygon $Graphics $color $points 512
        }
        for ($i = 0; $i -lt 26; $i++) {
            $x = $random.Next(-32, 512)
            $y = $random.Next(-32, 512)
            $w = $random.Next(36, 112)
            $h = $random.Next(10, 26)
            Fill-WrappedRect $Graphics $colors[($i + 2) % $colors.Count] $x $y $w $h 512
        }
    }
}

function Draw-DigitalPattern([System.Drawing.Bitmap]$Bitmap, $Definition) {
    $random = New-SeedRandom $Definition.Id
    $colors = @($Definition.Palette | ForEach-Object { ConvertTo-Color $_ })
    Use-Graphics $Bitmap {
        param($Graphics)
        for ($i = 0; $i -lt 260; $i++) {
            $grid = 8
            $x = $random.Next(0, 64) * $grid
            $y = $random.Next(0, 64) * $grid
            $w = $grid * $random.Next(1, 8)
            $h = $grid * $random.Next(1, 6)
            $color = $colors[1 + $random.Next($colors.Count - 1)]
            Fill-WrappedRect $Graphics $color $x $y $w $h 512
        }
        for ($i = 0; $i -lt 68; $i++) {
            $grid = 16
            $x = $random.Next(0, 32) * $grid
            $y = $random.Next(0, 32) * $grid
            $w = $grid * $random.Next(2, 7)
            $h = $grid * $random.Next(1, 4)
            Fill-WrappedRect $Graphics $colors[1 + $random.Next($colors.Count - 1)] $x $y $w $h 512
        }
    }
}

function Draw-TigerPattern([System.Drawing.Bitmap]$Bitmap, $Definition) {
    $random = New-SeedRandom $Definition.Id
    $colors = @($Definition.Palette | ForEach-Object { ConvertTo-Color $_ })
    Use-Graphics $Bitmap {
        param($Graphics)
        Draw-MacroPattern $Bitmap $Definition
        for ($i = 0; $i -lt 30; $i++) {
            $y = $random.Next(-60, 540)
            $x = $random.Next(-80, 420)
            $len = $random.Next(150, 330)
            $thick = $random.Next(14, 34)
            $points = @(
                [System.Drawing.PointF]::new($x, $y),
                [System.Drawing.PointF]::new($x + $len * 0.38, $y + $random.Next(-24, 20)),
                [System.Drawing.PointF]::new($x + $len, $y + $random.Next(20, 76)),
                [System.Drawing.PointF]::new($x + $len * 0.62, $y + $thick + $random.Next(0, 32)),
                [System.Drawing.PointF]::new($x + 20, $y + $thick)
            )
            Fill-WrappedPolygon $Graphics $colors[$colors.Count - 1] $points 512
        }
    }
}

function Draw-SolidPattern([System.Drawing.Bitmap]$Bitmap, $Definition) {
    $colors = @($Definition.Palette | ForEach-Object { ConvertTo-Color $_ })
    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($colors[0])
        Fill-WrappedRect $Graphics $colors[1] 0 0 512 18 512
        Fill-WrappedRect $Graphics $colors[2] 0 494 512 18 512
    }
}

function Draw-WhitewashPattern([System.Drawing.Bitmap]$Bitmap, $Definition) {
    Draw-MacroPattern $Bitmap $Definition
    $random = New-SeedRandom ($Definition.Id + "_scrape")
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 255, 255, 255))
    try {
        Use-Graphics $Bitmap {
            param($Graphics)
            for ($i = 0; $i -lt 42; $i++) {
                $Graphics.FillRectangle($brush, $random.Next(-20, 512), $random.Next(0, 512), $random.Next(38, 150), $random.Next(5, 18))
            }
        }
    }
    finally {
        $brush.Dispose()
    }
}

function New-ResizedBitmap([System.Drawing.Bitmap]$Source, [int]$Size) {
    $target = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($target)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    try {
        $graphics.DrawImage($Source, [System.Drawing.Rectangle]::new(0, 0, $Size, $Size), [System.Drawing.Rectangle]::new(0, 0, $Source.Width, $Source.Height), [System.Drawing.GraphicsUnit]::Pixel)
    }
    finally {
        $graphics.Dispose()
    }
    return $target
}

function Save-CamoResources($Definition) {
    $dir = Join-Path $textureRoot $Definition.Id
    Ensure-Dir $dir
    $bitmap = New-Bitmap 512 $Definition.Palette[0]
    try {
        switch ($Definition.Style) {
            "macro" { Draw-MacroPattern $bitmap $Definition }
            "splinter" { Draw-SplinterPattern $bitmap $Definition }
            "digital" { Draw-DigitalPattern $bitmap $Definition }
            "tiger" { Draw-TigerPattern $bitmap $Definition }
            "solid" { Draw-SolidPattern $bitmap $Definition }
            "whitewash" { Draw-WhitewashPattern $bitmap $Definition }
        }
        $sample = New-ResizedBitmap $bitmap 256
        try {
            $bitmap.Save((Join-Path $dir "variant_0.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $sample.Save((Join-Path $dir "variant_1.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $sample.Dispose()
        }
    }
    finally {
        $bitmap.Dispose()
    }

    Save-BlockResources $Definition "standard" 64 "Standard"
    if ($Definition.HasLarge) {
        Save-BlockResources $Definition "large" 32 "Large"
    }
}

function Save-BlockResources($Definition, [string]$SizeId, [int]$TilePixels, [string]$SizeEn) {
    $blockId = "$($Definition.Id)_${SizeId}_block"
    $textureBase = "camowarfare:block/$($Definition.Id)"

    Save-Json (Join-Path $blockstateRoot ($blockId + ".json")) ([ordered]@{
        multipart = @([ordered]@{ apply = [ordered]@{ model = "camowarfare:block/${blockId}_0" } })
    })
    Save-Json (Join-Path $blockModelRoot ($blockId + ".json")) ([ordered]@{
        parent = "camowarfare:block/${blockId}_0"
        render_type = "minecraft:solid"
        textures = [ordered]@{ particle = "$textureBase/variant_1" }
    })
    Save-Json (Join-Path $blockModelRoot ($blockId + "_0.json")) ([ordered]@{
        parent = "minecraft:block/block"
        render_type = "minecraft:cutout"
        loader = "camowarfare:connected_camo"
        position_tiled = $true
        position_tile_pixels = $TilePixels
        textures = [ordered]@{
            atlas = "$textureBase/variant_0"
            particle = "$textureBase/variant_1"
            copycat_atlas = "$textureBase/variant_1"
            edge = "camowarfare:block/definition_sample/edge"
            rivet = "camowarfare:block/definition_sample/rivet"
        }
    })
    Save-Json (Join-Path $itemModelRoot ($blockId + ".json")) ([ordered]@{
        parent = "minecraft:block/cube_all"
        textures = [ordered]@{ all = "$textureBase/variant_1" }
    })
    Save-Json (Join-Path $lootRoot ($blockId + ".json")) ([ordered]@{
        type = "minecraft:block"
        pools = @([ordered]@{
            rolls = 1.0
            bonus_rolls = 0.0
            entries = @([ordered]@{ type = "minecraft:item"; name = "camowarfare:$blockId" })
            conditions = @([ordered]@{ condition = "minecraft:survives_explosion" })
        })
    })
}

$definitions = @(
    @{ Id = "woodland_blotch"; En = "Woodland Blotch"; Style = "macro"; HasLarge = $true; Palette = @("#344026", "#4F5D36", "#6D7846", "#8A6A42", "#202719") },
    @{ Id = "russian_green_splinter"; En = "Deep Green Splinter"; Style = "splinter"; HasLarge = $true; Palette = @("#25301F", "#3E4D2E", "#5C6B40", "#778052", "#191F16") },
    @{ Id = "ukrainian_yellow_green"; En = "Yellow-Green Mixed Camo"; Style = "macro"; HasLarge = $true; Palette = @("#445321", "#687934", "#9AA65A", "#B7A654", "#273116") },
    @{ Id = "pla_mountain_tiger"; En = "Mountain Tiger Stripe"; Style = "tiger"; HasLarge = $true; Palette = @("#505A42", "#70775A", "#8D8467", "#A29378", "#2A3024") },
    @{ Id = "russian_desert"; En = "Sand Splinter"; Style = "splinter"; HasLarge = $true; Palette = @("#725538", "#98754C", "#B89363", "#D3BC8C", "#4D3828") },
    @{ Id = "desert_brush"; En = "Desert Brush"; Style = "splinter"; HasLarge = $true; Palette = @("#826241", "#A17C50", "#C09B6C", "#DDC194", "#5B4330") },
    @{ Id = "winter_whitewash"; En = "Winter Whitewash"; Style = "whitewash"; HasLarge = $true; Palette = @("#9DA7A8", "#C4CCCB", "#E8ECEA", "#F7F8F5", "#687273") },
    @{ Id = "snow_graywhite_digital"; En = "Snow Gray-White Digital"; Style = "digital"; HasLarge = $true; Palette = @("#5E676D", "#8E999E", "#C0C9CB", "#E7EBEA", "#F8F9F7") },
    @{ Id = "solid_night_black"; En = "Night Black"; Style = "solid"; HasLarge = $false; Palette = @("#191D21", "#2A3036", "#0B0E11") },
    @{ Id = "night_lowvis_digital"; En = "Night Low-Vis Digital"; Style = "digital"; HasLarge = $true; Palette = @("#111519", "#1E252B", "#303940", "#46505A", "#090C0F") },
    @{ Id = "solid_bluegray"; En = "Deep Blue-Gray"; Style = "solid"; HasLarge = $false; Palette = @("#263F5E", "#365A83", "#14263A") },
    @{ Id = "coastal_blue_digital"; En = "Coastal Blue Digital"; Style = "digital"; HasLarge = $true; Palette = @("#23425A", "#3E6D87", "#5F8FA8", "#9EB8C8", "#162B3B") },
    @{ Id = "ocean_blue_digital"; En = "Ocean Blue Digital"; Style = "digital"; HasLarge = $true; Palette = @("#18314F", "#25557C", "#3478A2", "#72A8C7", "#0D2034") },
    @{ Id = "urban_digital"; En = "Urban Digital"; Style = "digital"; HasLarge = $true; Palette = @("#2F3539", "#535C62", "#7B8589", "#B4BAB9", "#171C20") },
    @{ Id = "urban_gray_splinter"; En = "Urban Gray Hull Block"; Style = "splinter"; HasLarge = $false; Palette = @("#2F3538", "#565E62", "#838A8D", "#B7BDBC", "#191D20") },
    @{ Id = "solid_military_green"; En = "Military Green"; Style = "solid"; HasLarge = $false; Palette = @("#3E4C32", "#536440", "#242F20") },
    @{ Id = "solid_desert_sand"; En = "Desert Sand"; Style = "solid"; HasLarge = $false; Palette = @("#B79A68", "#D0BB8D", "#7F6341") },
    @{ Id = "us_carc_green383"; En = "US CARC Green 383"; Style = "solid"; HasLarge = $false; Palette = @("#33452F", "#4D633F", "#1B2619") },
    @{ Id = "us_carc_desert_tan"; En = "US CARC Desert Tan"; Style = "solid"; HasLarge = $false; Palette = @("#B69A6A", "#D1BC8A", "#7B6342") },
    @{ Id = "us_carc_blackgray"; En = "US CARC Black-Gray"; Style = "solid"; HasLarge = $false; Palette = @("#24282C", "#3B4248", "#111417") }
)

$obsoleteFamilies = @(
    "nato_woodland_riveted", "nato_woodland_stained", "nato_woodland_weathered",
    "woodland_macro", "woodland_macro_riveted", "woodland_macro_stained", "woodland_macro_weathered",
    "stryker_deep_olive", "stryker_deep_olive_riveted", "stryker_deep_olive_stained", "stryker_deep_olive_weathered",
    "woodland_digital",
    "ukrainian_yellow_green_riveted", "ukrainian_yellow_green_stained", "ukrainian_yellow_green_weathered",
    "pla_mountain", "pla_mountain_digital", "pla_mountain_riveted", "pla_mountain_stained", "pla_mountain_weathered",
    "nato_desert", "nato_desert_riveted", "nato_desert_weathered", "desert_modern", "desert_digital",
    "winter_whitewash_hull", "winter_whitewash_riveted", "winter_whitewash_stained", "winter_whitewash_weathered",
    "snow_graywhite_camo", "snow_graywhite_splinter",
    "black_night", "black_night_hull", "black_night_riveted", "black_night_stained", "black_night_weathered", "night_lowvis_camo", "night_lowvis_splinter",
    "naval_bluegray", "naval_bluegray_camo", "naval_bluegray_digital", "naval_bluegray_splinter", "naval_bluegray_riveted", "naval_bluegray_stained", "naval_bluegray_weathered",
    "pla_05_naval_blue", "pla_05_naval_blue_hull", "pla_05_naval_blue_riveted",
    "urban_digital_hull", "urban_digital_riveted", "urban_digital_stained", "urban_digital_weathered", "urban_gray_camo", "urban_gray_digital",
    "solid_desert_sand_number", "solid_military_green_number", "solid_military_green_stripe", "solid_night_black_lowvis_number",
    "riveted_armor_green", "riveted_desert_sand", "stained_armor_green", "stained_steel_bluegray", "weathered_armor_green", "weathered_desert_sand"
)

$resetIds = @($definitions | ForEach-Object { $_.Id })
$cleanupFamilies = @($obsoleteFamilies + $resetIds | Select-Object -Unique)

foreach ($family in $cleanupFamilies) {
    $dir = Join-Path $textureRoot $family
    Assert-ChildPath $textureRoot $dir
    if (Test-Path -LiteralPath $dir) {
        Remove-Item -LiteralPath $dir -Recurse -Force
    }

    $patterns = @(
        "${family}_*_block.json",
        "${family}_block.json",
        "${family}_*_appearance.json"
    )
    foreach ($pattern in $patterns) {
        foreach ($base in @($blockstateRoot, $blockModelRoot, $itemModelRoot, $lootRoot)) {
            foreach ($file in Get-ChildItem -LiteralPath $base -File -Filter $pattern -ErrorAction SilentlyContinue) {
                Assert-ChildPath $base $file.FullName
                Remove-Item -LiteralPath $file.FullName -Force
            }
        }
    }
}

foreach ($definition in $definitions) {
    Save-CamoResources $definition
}

$validBlockIds = [System.Collections.Generic.HashSet[string]]::new()
foreach ($definition in $definitions) {
    $validBlockIds.Add("camowarfare:$($definition.Id)_standard_block") | Out-Null
    if ($definition.HasLarge) {
        $validBlockIds.Add("camowarfare:$($definition.Id)_large_block") | Out-Null
    }
}

function Clean-And-AddTag([string]$Path) {
    $json = Load-Json $Path
    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($existing in $json.values) {
        $value = [string]$existing
        $remove = $false
        foreach ($family in $cleanupFamilies) {
            if ($value -match "^camowarfare:$([regex]::Escape($family))(_|_.*_|_.*)?block$" -or $value -like "camowarfare:${family}_*") {
                $remove = $true
                break
            }
        }
        if (-not $remove -and -not $values.Contains($value)) {
            $values.Add($value)
        }
    }
    foreach ($blockId in $validBlockIds) {
        if (-not $values.Contains($blockId)) {
            $values.Add($blockId)
        }
    }
    Save-Json $Path ([ordered]@{ replace = [bool]$json.replace; values = @($values) })
}

Clean-And-AddTag $pickaxeTagPath
Clean-And-AddTag $armoredTagPath

$en = Load-Json $enLangPath
foreach ($prop in @($en.PSObject.Properties)) {
    if ($prop.Name -like "block.camowarfare.*") {
        foreach ($family in $cleanupFamilies) {
            if ($prop.Name -like "block.camowarfare.${family}_*" -or $prop.Name -eq "block.camowarfare.${family}_block") {
                $en.PSObject.Properties.Remove($prop.Name)
                break
            }
        }
    }
}
foreach ($definition in $definitions) {
    $en | Add-Member -NotePropertyName "block.camowarfare.$($definition.Id)_standard_block" -NotePropertyValue "$($definition.En) Coating Block (Standard)" -Force
    if ($definition.HasLarge) {
        $en | Add-Member -NotePropertyName "block.camowarfare.$($definition.Id)_large_block" -NotePropertyValue "$($definition.En) Coating Block (Large)" -Force
    }
}
Save-Json $enLangPath $en

Write-Output ("Reset camo definitions: " + $definitions.Count)
Write-Output ("Removed old family resource groups: " + $obsoleteFamilies.Count)
