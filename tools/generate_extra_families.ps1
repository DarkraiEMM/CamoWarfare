$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$resourcesRoot = Join-Path $projectRoot "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"

$families = @(
    [ordered]@{
        Id = "stryker_deep_olive"
        En = "Stryker Deep Olive"
        Type = "solid"
        Palette = @("#3D4A2E", "#536443", "#2B3322", "#6D7B59")
    },
    [ordered]@{
        Id = "pla_05_naval_blue"
        En = "PLA 05 Naval Blue"
        Type = "navy"
        Palette = @("#314860", "#46617B", "#243344", "#607A93")
    },
    [ordered]@{
        Id = "ukrainian_yellow_green"
        En = "Ukrainian Yellow-Green"
        Type = "macro"
        Palette = @("#7D8A47", "#B7A252", "#5A612F", "#4D3D27")
    },
    [ordered]@{
        Id = "pla_woodland"
        En = "PLA Woodland"
        Type = "digital"
        Palette = @("#546541", "#6E7B4B", "#84704A", "#26311E")
    },
    [ordered]@{
        Id = "pla_mountain"
        En = "PLA Mountain"
        Type = "mountain"
        Palette = @("#687051", "#8B8564", "#565946", "#8A6A50")
    },
    [ordered]@{
        Id = "riveted_armor_green"
        En = "Riveted Armor Green"
        Type = "riveted"
        Palette = @("#46533A", "#55654A", "#384233", "#657358")
    },
    [ordered]@{
        Id = "riveted_desert_sand"
        En = "Riveted Desert Sand"
        Type = "riveted"
        Palette = @("#9A865F", "#AA9671", "#847257", "#B59F79")
    },
    [ordered]@{
        Id = "stained_armor_green"
        En = "Stained Armor Green"
        Type = "stained"
        Palette = @("#48563D", "#5C6B4E", "#374134", "#2B3329")
    },
    [ordered]@{
        Id = "stained_steel_bluegray"
        En = "Stained Steel Blue-Gray"
        Type = "stained"
        Palette = @("#5A6975", "#6A7C89", "#47545F", "#39444C")
    },
    [ordered]@{
        Id = "weathered_armor_green"
        En = "Weathered Armor Green"
        Type = "weathered"
        Palette = @("#4B583E", "#5E6D4E", "#394333", "#6B715C")
    },
    [ordered]@{
        Id = "weathered_desert_sand"
        En = "Weathered Desert Sand"
        Type = "weathered"
        Palette = @("#A18D66", "#B09B75", "#897658", "#9C896F")
    }
)

$variants = @("a", "b", "c")
$allRegisteredFamilies = @(
    [ordered]@{ Id = "nato_woodland"; Legacy = "nato_woodland_block" },
    [ordered]@{ Id = "russian_green_splinter"; Legacy = "russian_green_splinter_block" },
    [ordered]@{ Id = "russian_desert"; Legacy = "russian_desert_block" },
    [ordered]@{ Id = "nato_desert"; Legacy = "nato_desert_block" },
    [ordered]@{ Id = "woodland_digital"; Legacy = "woodland_digital_block" },
    [ordered]@{ Id = "desert_digital"; Legacy = "desert_digital_block" },
    [ordered]@{ Id = "urban_digital"; Legacy = "urban_digital_block" },
    [ordered]@{ Id = "naval_bluegray"; Legacy = "naval_bluegray_block" },
    [ordered]@{ Id = "winter_whitewash"; Legacy = "winter_whitewash_block" },
    [ordered]@{ Id = "black_night"; Legacy = "black_night_block" },
    [ordered]@{ Id = "solid_military_green"; Legacy = $null },
    [ordered]@{ Id = "solid_desert_sand"; Legacy = $null },
    [ordered]@{ Id = "solid_bluegray"; Legacy = $null },
    [ordered]@{ Id = "solid_night_black"; Legacy = $null },
    [ordered]@{ Id = "stryker_deep_olive"; Legacy = $null },
    [ordered]@{ Id = "pla_05_naval_blue"; Legacy = $null },
    [ordered]@{ Id = "ukrainian_yellow_green"; Legacy = $null },
    [ordered]@{ Id = "pla_woodland"; Legacy = $null },
    [ordered]@{ Id = "pla_mountain"; Legacy = $null },
    [ordered]@{ Id = "riveted_armor_green"; Legacy = $null },
    [ordered]@{ Id = "riveted_desert_sand"; Legacy = $null },
    [ordered]@{ Id = "stained_armor_green"; Legacy = $null },
    [ordered]@{ Id = "stained_steel_bluegray"; Legacy = $null },
    [ordered]@{ Id = "weathered_armor_green"; Legacy = $null },
    [ordered]@{ Id = "weathered_desert_sand"; Legacy = $null }
)

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Write-Utf8File([string]$Path, [string]$Content) {
    Ensure-Directory (Split-Path -Parent $Path)
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Write-JsonFile([string]$Path, $Object) {
    Write-Utf8File $Path (($Object | ConvertTo-Json -Depth 20) + "`n")
}

function ConvertTo-OrderedHashtable([string]$Path) {
    $raw = Get-Content $Path -Raw
    $object = $raw | ConvertFrom-Json
    $hash = [ordered]@{}
    foreach ($property in $object.PSObject.Properties) {
        $hash[$property.Name] = $property.Value
    }
    return $hash
}

function New-DeterministicRandom([string]$Key) {
    return [System.Random]::new([Math]::Abs($Key.GetHashCode()))
}

function ConvertTo-Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
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

function Fill-WrappedRect([System.Drawing.Graphics]$Graphics, [System.Drawing.Color]$Color, [float]$X, [float]$Y, [float]$Width, [float]$Height) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        foreach ($offsetX in @(-128, 0, 128)) {
            foreach ($offsetY in @(-128, 0, 128)) {
                $Graphics.FillRectangle($brush, $X + $offsetX, $Y + $offsetY, $Width, $Height)
            }
        }
    }
    finally {
        $brush.Dispose()
    }
}

function Fill-WrappedEllipse([System.Drawing.Graphics]$Graphics, [System.Drawing.Color]$Color, [float]$X, [float]$Y, [float]$Width, [float]$Height) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        foreach ($offsetX in @(-128, 0, 128)) {
            foreach ($offsetY in @(-128, 0, 128)) {
                $Graphics.FillEllipse($brush, $X + $offsetX, $Y + $offsetY, $Width, $Height)
            }
        }
    }
    finally {
        $brush.Dispose()
    }
}

function Draw-WrappedLine([System.Drawing.Graphics]$Graphics, [System.Drawing.Color]$Color, [float]$X1, [float]$Y1, [float]$X2, [float]$Y2, [float]$Width) {
    $pen = [System.Drawing.Pen]::new($Color, $Width)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    try {
        foreach ($offsetX in @(-128, 0, 128)) {
            foreach ($offsetY in @(-128, 0, 128)) {
                $Graphics.DrawLine($pen, $X1 + $offsetX, $Y1 + $offsetY, $X2 + $offsetX, $Y2 + $offsetY)
            }
        }
    }
    finally {
        $pen.Dispose()
    }
}

function Clamp([int]$Value, [int]$Minimum, [int]$Maximum) {
    return [Math]::Min($Maximum, [Math]::Max($Minimum, $Value))
}

function Paint-QuietBorder([System.Drawing.Graphics]$Graphics, [System.Drawing.Color[]]$Colors) {
    $base = $Colors[0]
    $dark = $Colors[2]

    $baseBrush = [System.Drawing.SolidBrush]::new($base)
    $darkBrush = [System.Drawing.SolidBrush]::new($dark)
    try {
        $Graphics.FillRectangle($baseBrush, 0, 0, 128, 6)
        $Graphics.FillRectangle($baseBrush, 0, 122, 128, 6)
        $Graphics.FillRectangle($baseBrush, 0, 0, 6, 128)
        $Graphics.FillRectangle($baseBrush, 122, 0, 6, 128)
        $Graphics.FillRectangle($darkBrush, 0, 0, 128, 1)
        $Graphics.FillRectangle($darkBrush, 0, 127, 128, 1)
        $Graphics.FillRectangle($darkBrush, 0, 0, 1, 128)
        $Graphics.FillRectangle($darkBrush, 127, 0, 1, 128)
    }
    finally {
        $baseBrush.Dispose()
        $darkBrush.Dispose()
    }
}

function Paint-PanelAccents([System.Drawing.Graphics]$Graphics, [System.Drawing.Color[]]$Colors, [System.Random]$Random, [string]$Variant) {
    $light = $Colors[1]
    $dark = $Colors[2]

    for ($i = 0; $i -lt 5; $i++) {
        $x = 24 + $Random.Next(54)
        $y = 24 + $Random.Next(52)
        $w = 12 + $Random.Next(20)
        Fill-WrappedRect $Graphics $light $x $y $w 2
        if ($Random.NextDouble() -gt 0.45) {
            Fill-WrappedRect $Graphics $dark ($x + 2) ($y + 6 + $Random.Next(10)) (4 + $Random.Next(10)) 2
        }
    }

    if ($Variant -eq "b") {
        Draw-WrappedLine $Graphics $dark 42 28 46 96 1.25
    }

    if ($Variant -eq "c") {
        for ($i = 0; $i -lt 5; $i++) {
            Fill-WrappedEllipse $Graphics $light (30 + $Random.Next(60)) (30 + $Random.Next(56)) 4 4
        }
    }
}

function Paint-RivetLines([System.Drawing.Graphics]$Graphics, [System.Drawing.Color[]]$Colors, [System.Random]$Random, [string]$Variant) {
    $light = $Colors[1]
    $dark = $Colors[2]
    $x = 28 + $Random.Next(20)
    $y = 34 + $Random.Next(18)
    Fill-WrappedRect $Graphics $light $x $y 2 56
    for ($i = 0; $i -lt 5; $i++) {
        Fill-WrappedEllipse $Graphics $dark ($x - 1) ($y + 6 + $i * 10) 4 4
    }

    $hx = 50 + $Random.Next(20)
    $hy = 60 + $Random.Next(14)
    Fill-WrappedRect $Graphics $light $hx $hy 28 2
    for ($i = 0; $i -lt 3; $i++) {
        Fill-WrappedEllipse $Graphics $dark ($hx + 4 + $i * 10) ($hy - 1) 4 4
    }

    if ($Variant -eq "b") {
        Fill-WrappedRect $Graphics $dark 64 30 2 42
        for ($i = 0; $i -lt 3; $i++) {
            Fill-WrappedEllipse $Graphics $light 63 (34 + $i * 12) 4 4
        }
    }

    if ($Variant -eq "c") {
        for ($i = 0; $i -lt 4; $i++) {
            Fill-WrappedEllipse $Graphics $dark (34 + $Random.Next(52)) (34 + $Random.Next(52)) 4 4
        }
    }
}

function Paint-Stains([System.Drawing.Graphics]$Graphics, [System.Drawing.Color[]]$Colors, [System.Random]$Random, [string]$Variant) {
    $stain = $Colors[3]
    $shadow = $Colors[2]

    for ($i = 0; $i -lt 5; $i++) {
        $x = 26 + $Random.Next(54)
        $y = 24 + $Random.Next(56)
        Fill-WrappedEllipse $Graphics $stain $x $y (12 + $Random.Next(14)) (8 + $Random.Next(12))
        Draw-WrappedLine $Graphics $shadow ($x + 6) ($y + 6) ($x + 3 + $Random.Next(14)) (66 + $Random.Next(20)) 1.25
    }

    if ($Variant -eq "b") {
        Draw-WrappedLine $Graphics $shadow 52 30 58 88 1.5
        Draw-WrappedLine $Graphics $shadow 74 36 78 82 1.5
    }

    if ($Variant -eq "c") {
        for ($i = 0; $i -lt 7; $i++) {
            Fill-WrappedEllipse $Graphics $shadow (30 + $Random.Next(62)) (32 + $Random.Next(56)) 3 3
        }
    }
}

function Paint-Weathering([System.Drawing.Graphics]$Graphics, [System.Drawing.Color[]]$Colors, [System.Random]$Random, [string]$Variant) {
    $light = $Colors[1]
    $dark = $Colors[2]
    $rust = $Colors[3]

    for ($i = 0; $i -lt 8; $i++) {
        $x = 22 + $Random.Next(64)
        $y = 24 + $Random.Next(56)
        Fill-WrappedRect $Graphics $light $x $y (8 + $Random.Next(12)) 2
        Fill-WrappedRect $Graphics $dark ($x + 2) ($y + 2) (4 + $Random.Next(8)) 2
    }

    for ($i = 0; $i -lt 4; $i++) {
        Fill-WrappedEllipse $Graphics $rust (32 + $Random.Next(52)) (34 + $Random.Next(44)) (5 + $Random.Next(8)) (4 + $Random.Next(6))
    }

    if ($Variant -eq "b") {
        Draw-WrappedLine $Graphics $dark 34 40 88 78 1.5
        Draw-WrappedLine $Graphics $light 38 44 84 72 1
    }

    if ($Variant -eq "c") {
        for ($i = 0; $i -lt 6; $i++) {
            Fill-WrappedRect $Graphics $rust (30 + $Random.Next(56)) (28 + $Random.Next(56)) 4 2
        }
    }
}

function New-SampleBitmap($Family, [string]$Variant) {
    $bitmap = New-Bitmap 128 128
    $random = New-DeterministicRandom ($Family.Id + "-" + $Variant)
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }

    Use-Graphics $bitmap {
        param($graphics)
        $graphics.Clear($colors[0])

        switch ($Family.Type) {
            "solid" {
                for ($i = 0; $i -lt 8; $i++) {
                    $x = 22 + $random.Next(58)
                    $y = 22 + $random.Next(58)
                    Fill-WrappedRect $graphics $colors[1] $x $y (18 + $random.Next(22)) (10 + $random.Next(14))
                }
                Paint-PanelAccents $graphics $colors $random $Variant
            }
            "navy" {
                for ($i = 0; $i -lt 7; $i++) {
                    $x = 24 + $random.Next(54)
                    $y = 24 + $random.Next(54)
                    Fill-WrappedRect $graphics $colors[1] $x $y (18 + $random.Next(20)) (8 + $random.Next(12))
                }
                for ($i = 0; $i -lt 10; $i++) {
                    Fill-WrappedEllipse $graphics $colors[3] (26 + $random.Next(68)) (26 + $random.Next(68)) (6 + $random.Next(10)) (4 + $random.Next(8))
                }
                Paint-PanelAccents $graphics $colors $random $Variant
            }
            "digital" {
                for ($i = 0; $i -lt 90; $i++) {
                    $grid = 4
                    $x = Clamp ((5 + $random.Next(22)) * $grid) 20 92
                    $y = Clamp ((5 + $random.Next(22)) * $grid) 20 92
                    Fill-WrappedRect $graphics $colors[1 + $random.Next(3)] $x $y ((1 + $random.Next(3)) * $grid) ((1 + $random.Next(3)) * $grid)
                }
            }
            "mountain" {
                for ($i = 0; $i -lt 28; $i++) {
                    Fill-WrappedEllipse $graphics $colors[1 + $random.Next(3)] (24 + $random.Next(64)) (24 + $random.Next(64)) (14 + $random.Next(22)) (10 + $random.Next(16))
                }
                for ($i = 0; $i -lt 12; $i++) {
                    Draw-WrappedLine $graphics $colors[2] (24 + $random.Next(80)) (24 + $random.Next(80)) (24 + $random.Next(80)) (24 + $random.Next(80)) 2.5
                }
            }
            "riveted" {
                for ($i = 0; $i -lt 5; $i++) {
                    $x = 24 + $random.Next(56)
                    $y = 24 + $random.Next(56)
                    Fill-WrappedRect $graphics $colors[1] $x $y (16 + $random.Next(20)) (8 + $random.Next(12))
                }
                Paint-PanelAccents $graphics $colors $random $Variant
                Paint-RivetLines $graphics $colors $random $Variant
            }
            "stained" {
                for ($i = 0; $i -lt 6; $i++) {
                    $x = 24 + $random.Next(56)
                    $y = 24 + $random.Next(56)
                    Fill-WrappedRect $graphics $colors[1] $x $y (16 + $random.Next(18)) (8 + $random.Next(10))
                }
                Paint-PanelAccents $graphics $colors $random $Variant
                Paint-Stains $graphics $colors $random $Variant
            }
            "weathered" {
                for ($i = 0; $i -lt 6; $i++) {
                    $x = 24 + $random.Next(56)
                    $y = 24 + $random.Next(56)
                    Fill-WrappedRect $graphics $colors[1] $x $y (16 + $random.Next(18)) (8 + $random.Next(10))
                }
                Paint-PanelAccents $graphics $colors $random $Variant
                Paint-Weathering $graphics $colors $random $Variant
            }
            default {
                for ($i = 0; $i -lt 24; $i++) {
                    Fill-WrappedEllipse $graphics $colors[1 + $random.Next(3)] (22 + $random.Next(72)) (22 + $random.Next(72)) (18 + $random.Next(20)) (12 + $random.Next(16))
                }
                for ($i = 0; $i -lt 8; $i++) {
                    Fill-WrappedRect $graphics $colors[2] (26 + $random.Next(66)) (26 + $random.Next(66)) (8 + $random.Next(12)) (8 + $random.Next(10))
                }
            }
        }

        Paint-QuietBorder $graphics $colors
    }

    return $bitmap
}

function Add-MaskDetail([System.Drawing.Bitmap]$Bitmap, [int]$Mask, $Family) {
    $random = New-DeterministicRandom ($Family.Id + "-mask-" + $Mask)
    $colors = $Family.Palette | ForEach-Object { ConvertTo-Color $_ }

    Use-Graphics $Bitmap {
        param($graphics)
        $bandColor = $colors[1]
        $lineColor = $colors[2]

        if ($Mask -band 1) {
            Fill-WrappedRect $graphics $bandColor (14 + $random.Next(16)) 0 (22 + $random.Next(18)) 6
            Fill-WrappedRect $graphics $bandColor (58 + $random.Next(18)) 0 (18 + $random.Next(16)) 6
            Fill-WrappedRect $graphics $lineColor 0 6 128 1
        }
        if ($Mask -band 2) {
            Fill-WrappedRect $graphics $bandColor 122 (14 + $random.Next(16)) 6 (22 + $random.Next(18))
            Fill-WrappedRect $graphics $bandColor 122 (58 + $random.Next(18)) 6 (18 + $random.Next(16))
            Fill-WrappedRect $graphics $lineColor 121 0 1 128
        }
        if ($Mask -band 4) {
            Fill-WrappedRect $graphics $bandColor (14 + $random.Next(16)) 122 (22 + $random.Next(18)) 6
            Fill-WrappedRect $graphics $bandColor (58 + $random.Next(18)) 122 (18 + $random.Next(16)) 6
            Fill-WrappedRect $graphics $lineColor 0 121 128 1
        }
        if ($Mask -band 8) {
            Fill-WrappedRect $graphics $bandColor 0 (14 + $random.Next(16)) 6 (22 + $random.Next(18))
            Fill-WrappedRect $graphics $bandColor 0 (58 + $random.Next(18)) 6 (18 + $random.Next(16))
            Fill-WrappedRect $graphics $lineColor 6 0 1 128
        }
    }
}

$enLangPath = Join-Path $assetsRoot "lang\en_us.json"
$pickaxePath = Join-Path $resourcesRoot "data\minecraft\tags\block\mineable\pickaxe.json"

$enLang = ConvertTo-OrderedHashtable $enLangPath
$pickaxeValues = New-Object System.Collections.Generic.List[string]

foreach ($family in $families) {
    $textureDir = Join-Path $assetsRoot ("textures\block\" + $family.Id)
    Ensure-Directory $textureDir

    foreach ($variant in $variants) {
        $sample = New-SampleBitmap $family $variant
        $samplePath = Join-Path $textureDir ($variant + "_atlas.png")
        $sample.Save($samplePath, [System.Drawing.Imaging.ImageFormat]::Png)

        $atlas = New-Bitmap 512 512
        Use-Graphics $atlas {
            param($graphics)
            for ($mask = 0; $mask -lt 16; $mask++) {
                $tile = $sample.Clone([System.Drawing.Rectangle]::new(0, 0, 128, 128), $sample.PixelFormat)
                Add-MaskDetail $tile $mask $family
                $destination = [System.Drawing.Rectangle]::new(($mask % 4) * 128, [int][Math]::Floor($mask / 4) * 128, 128, 128)
                $graphics.DrawImage($tile, $destination)
                $tile.Dispose()
            }
        }
        $atlasPath = Join-Path $textureDir ($variant + ".png")
        $atlas.Save($atlasPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $sample.Dispose()
        $atlas.Dispose()

        $blockId = $family.Id + "_" + $variant + "_block"
        $atlasRef = "camowarfare:block/" + $family.Id + "/" + $variant
        $sampleRef = "camowarfare:block/" + $family.Id + "/" + $variant + "_atlas"

        $blockModel = [ordered]@{
            parent = "minecraft:block/block"
            render_type = "minecraft:solid"
            loader = "camowarfare:connected_camo"
            textures = [ordered]@{
                atlas = $atlasRef
                particle = $sampleRef
            }
        }
        $itemModel = [ordered]@{
            parent = "minecraft:block/block"
            render_type = "minecraft:solid"
            loader = "camowarfare:connected_camo"
            item_render = $true
            textures = [ordered]@{
                atlas = $atlasRef
                particle = $sampleRef
            }
        }
        $blockState = [ordered]@{
            multipart = @(
                [ordered]@{
                    apply = [ordered]@{
                        model = "camowarfare:block/" + $blockId
                    }
                }
            )
        }
        $loot = [ordered]@{
            type = "minecraft:block"
            pools = @(
                [ordered]@{
                    rolls = 1.0
                    bonus_rolls = 0.0
                    entries = @(
                        [ordered]@{
                            type = "minecraft:item"
                            name = "camowarfare:" + $blockId
                        }
                    )
                    conditions = @(
                        [ordered]@{
                            condition = "minecraft:survives_explosion"
                        }
                    )
                }
            )
        }

        Write-JsonFile (Join-Path $assetsRoot ("models\block\" + $blockId + ".json")) $blockModel
        Write-JsonFile (Join-Path $assetsRoot ("models\item\" + $blockId + ".json")) $itemModel
        Write-JsonFile (Join-Path $assetsRoot ("blockstates\" + $blockId + ".json")) $blockState
        Write-JsonFile (Join-Path $resourcesRoot ("data\camowarfare\loot_tables\blocks\" + $blockId + ".json")) $loot

        $variantLabel = $variant.ToUpperInvariant()
        $enLang["block.camowarfare." + $blockId] = $family.En + " Block " + $variantLabel
    }
}

foreach ($registeredFamily in $allRegisteredFamilies) {
    foreach ($variant in $variants) {
        $pickaxeValues.Add("camowarfare:" + $registeredFamily.Id + "_" + $variant + "_block")
    }
    if ($registeredFamily.Legacy) {
        $pickaxeValues.Add("camowarfare:" + $registeredFamily.Legacy)
    }
}

$pickaxe = [ordered]@{
    replace = $false
    values = @($pickaxeValues)
}

Write-JsonFile $enLangPath $enLang
Write-JsonFile $pickaxePath $pickaxe
