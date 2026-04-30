$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $root "src\main\resources\assets\camowarfare"
$dataRoot = Join-Path $root "src\main\resources\data"
$blockTextureRoot = Join-Path $assetsRoot "textures\block"
$blockstateRoot = Join-Path $assetsRoot "blockstates"
$blockModelRoot = Join-Path $assetsRoot "models\block"
$itemModelRoot = Join-Path $assetsRoot "models\item"
$lootRoot = Join-Path $dataRoot "camowarfare\loot_tables\blocks"
$langPath = Join-Path $assetsRoot "lang\en_us.json"
$pickaxeTagPath = Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json"
$armoredTagPath = Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json"

function Ensure-Dir($path) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

function Save-Json($path, $data) {
    Ensure-Dir (Split-Path -Parent $path)
    $json = $data | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($path, $json + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
}

function Load-Bitmap($path) {
    return [System.Drawing.Bitmap]::FromFile($path)
}

function New-Random([string]$seed) {
    return [System.Random]::new([Math]::Abs($seed.GetHashCode()))
}

function Scale16([int]$value, [int]$size) {
    return [int][Math]::Round(($value / 16.0) * $size)
}

function Fill-Rect($graphics, $brush, [int]$x16, [int]$y16, [int]$w16, [int]$h16, [int]$size) {
    $graphics.FillRectangle($brush, (Scale16 $x16 $size), (Scale16 $y16 $size), (Scale16 $w16 $size), (Scale16 $h16 $size))
}

function Fill-Ellipse($graphics, $brush, [int]$x16, [int]$y16, [int]$w16, [int]$h16, [int]$size) {
    $graphics.FillEllipse($brush, (Scale16 $x16 $size), (Scale16 $y16 $size), (Scale16 $w16 $size), (Scale16 $h16 $size))
}

function Draw-Line($graphics, $pen, [int]$x116, [int]$y116, [int]$x216, [int]$y216, [int]$size) {
    $graphics.DrawLine($pen, (Scale16 $x116 $size), (Scale16 $y116 $size), (Scale16 $x216 $size), (Scale16 $y216 $size))
}

function Apply-RivetedOverlay($bmp, $variant, $lightColor, $darkColor) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $size = $bmp.Width
    $light = New-Object System.Drawing.SolidBrush $lightColor
    $dark = New-Object System.Drawing.SolidBrush $darkColor
    try {
        Fill-Rect $g $light 2 3 1 10 $size
        Fill-Rect $g $light 12 4 1 8 $size
        Fill-Rect $g $light 4 11 8 1 $size

        foreach ($pt in @(@(2,4), @(2,7), @(2,10), @(12,5), @(12,8), @(5,11), @(8,11), @(11,11))) {
            Fill-Ellipse $g $dark $pt[0] $pt[1] 1 1 $size
        }

        if ($variant -eq "b" -or $variant -eq "d") {
            Fill-Rect $g $dark 7 3 1 9 $size
        }
        if ($variant -eq "c") {
            Fill-Rect $g $light 8 5 4 1 $size
        }
    }
    finally {
        $light.Dispose()
        $dark.Dispose()
        $g.Dispose()
    }
}

function Apply-StainedOverlay($bmp, $variant, $stainColor, $dripColor) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $size = $bmp.Width
    $stain = [System.Drawing.SolidBrush]::new($stainColor)
    $dripPen = [System.Drawing.Pen]::new($dripColor, [float][Math]::Max(1, $size / 80.0))
    try {
        Fill-Ellipse $g $stain 4 4 4 3 $size
        Fill-Ellipse $g $stain 9 6 3 2 $size
        Fill-Ellipse $g $stain 6 10 5 3 $size
        Draw-Line $g $dripPen 6 6 5 13 $size
        Draw-Line $g $dripPen 10 7 10 12 $size
        if ($variant -eq "b" -or $variant -eq "d") {
            Fill-Ellipse $g $stain 11 3 3 2 $size
        }
    }
    finally {
        $stain.Dispose()
        $dripPen.Dispose()
        $g.Dispose()
    }
}

function Apply-WeatheredOverlay($bmp, $variant, $chipColor, $shadowColor) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $size = $bmp.Width
    $chip = [System.Drawing.SolidBrush]::new($chipColor)
    $shadow = [System.Drawing.SolidBrush]::new($shadowColor)
    try {
        Fill-Rect $g $chip 3 4 3 1 $size
        Fill-Rect $g $chip 8 7 4 1 $size
        Fill-Rect $g $chip 5 11 3 1 $size
        Fill-Rect $g $shadow 4 5 2 1 $size
        Fill-Rect $g $shadow 9 8 2 1 $size
        if ($variant -eq "c" -or $variant -eq "d") {
            Fill-Rect $g $chip 11 4 2 1 $size
        }
    }
    finally {
        $chip.Dispose()
        $shadow.Dispose()
        $g.Dispose()
    }
}

$families = @(
    @{ Id = "naval_bluegray_riveted"; Source = "naval_bluegray"; Kind = "riveted"; Label = "Naval Blue-Gray Riveted" },
    @{ Id = "naval_bluegray_stained"; Source = "naval_bluegray"; Kind = "stained"; Label = "Naval Blue-Gray Stained" },
    @{ Id = "naval_bluegray_weathered"; Source = "naval_bluegray"; Kind = "weathered"; Label = "Naval Blue-Gray Weathered" },
    @{ Id = "winter_whitewash_riveted"; Source = "winter_whitewash"; Kind = "riveted"; Label = "Winter Whitewash Riveted" },
    @{ Id = "winter_whitewash_stained"; Source = "winter_whitewash"; Kind = "stained"; Label = "Winter Whitewash Stained" },
    @{ Id = "winter_whitewash_weathered"; Source = "winter_whitewash"; Kind = "weathered"; Label = "Winter Whitewash Weathered" },
    @{ Id = "black_night_riveted"; Source = "black_night"; Kind = "riveted"; Label = "Night Pattern Riveted" },
    @{ Id = "black_night_stained"; Source = "black_night"; Kind = "stained"; Label = "Night Pattern Stained" },
    @{ Id = "black_night_weathered"; Source = "black_night"; Kind = "weathered"; Label = "Night Pattern Weathered" },
    @{ Id = "urban_digital_riveted"; Source = "urban_digital"; Kind = "riveted"; Label = "Urban Digital Riveted" },
    @{ Id = "urban_digital_stained"; Source = "urban_digital"; Kind = "stained"; Label = "Urban Digital Stained" },
    @{ Id = "urban_digital_weathered"; Source = "urban_digital"; Kind = "weathered"; Label = "Urban Digital Weathered" }
)

foreach ($family in $families) {
    $familyTextureDir = Join-Path $blockTextureRoot $family.Id
    Ensure-Dir $familyTextureDir

    foreach ($variant in "a","b","c","d") {
        $srcSample = Join-Path (Join-Path $blockTextureRoot $family.Source) ($variant + "_atlas.png")
        $srcAtlas = Join-Path (Join-Path $blockTextureRoot $family.Source) ($variant + ".png")
        $sampleTarget = Join-Path $familyTextureDir ($variant + "_atlas.png")
        $atlasTarget = Join-Path $familyTextureDir ($variant + ".png")

        $sample = Load-Bitmap $srcSample
        $atlas = Load-Bitmap $srcAtlas
        try {
            switch ($family.Kind) {
                "riveted" {
                    $light = [System.Drawing.ColorTranslator]::FromHtml("#C0C7CD")
                    $dark = [System.Drawing.ColorTranslator]::FromHtml("#525A61")
                    Apply-RivetedOverlay $sample $variant $light $dark
                    Apply-RivetedOverlay $atlas $variant $light $dark
                }
                "stained" {
                    $stain = [System.Drawing.ColorTranslator]::FromHtml("#4D5257")
                    $drip = [System.Drawing.ColorTranslator]::FromHtml("#2C3136")
                    Apply-StainedOverlay $sample $variant $stain $drip
                    Apply-StainedOverlay $atlas $variant $stain $drip
                }
                "weathered" {
                    $chip = [System.Drawing.ColorTranslator]::FromHtml("#D0D5D8")
                    $shadow = [System.Drawing.ColorTranslator]::FromHtml("#5B6065")
                    Apply-WeatheredOverlay $sample $variant $chip $shadow
                    Apply-WeatheredOverlay $atlas $variant $chip $shadow
                }
            }

            $sample.Save($sampleTarget, [System.Drawing.Imaging.ImageFormat]::Png)
            $atlas.Save($atlasTarget, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $sample.Dispose()
            $atlas.Dispose()
        }

        $blockId = "$($family.Id)_${variant}_block"
        Save-Json (Join-Path $blockstateRoot ($blockId + ".json")) @{
            multipart = @(
                @{
                    apply = @{
                        model = "camowarfare:block/$blockId"
                    }
                }
            )
        }

        Save-Json (Join-Path $blockModelRoot ($blockId + ".json")) @{
            parent = "minecraft:block/block"
            render_type = "minecraft:solid"
            loader = "camowarfare:connected_camo"
            textures = @{
                atlas = "camowarfare:block/$($family.Id)/$variant"
                particle = "camowarfare:block/$($family.Id)/${variant}_atlas"
            }
        }

        Save-Json (Join-Path $itemModelRoot ($blockId + ".json")) @{
            parent = "minecraft:block/block"
            render_type = "minecraft:solid"
            loader = "camowarfare:connected_camo"
            item_render = $true
            textures = @{
                atlas = "camowarfare:block/$($family.Id)/$variant"
                particle = "camowarfare:block/$($family.Id)/${variant}_atlas"
            }
        }

        Save-Json (Join-Path $lootRoot ($blockId + ".json")) @{
            type = "minecraft:block"
            pools = @(
                @{
                    rolls = 1
                    entries = @(
                        @{
                            type = "minecraft:item"
                            name = "camowarfare:$blockId"
                        }
                    )
                    conditions = @(
                        @{
                            condition = "minecraft:survives_explosion"
                        }
                    )
                }
            )
        }
    }
}

$enLang = Get-Content -Raw -Path $langPath | ConvertFrom-Json
foreach ($family in $families) {
    foreach ($variant in "A","B","C","D") {
        $key = "block.camowarfare.$($family.Id)_$($variant.ToLower())_block"
        $value = "$($family.Label) $variant"
        Add-Member -InputObject $enLang -NotePropertyName $key -NotePropertyValue $value -Force
    }
}
Save-Json $langPath $enLang

foreach ($tagPath in @($pickaxeTagPath, $armoredTagPath)) {
    $json = Get-Content -Raw -Path $tagPath | ConvertFrom-Json
    $values = @($json.values)
    foreach ($family in $families) {
        foreach ($variant in "a","b","c","d") {
            $entry = "camowarfare:$($family.Id)_${variant}_block"
            if (-not ($values -contains $entry)) {
                $values += $entry
            }
        }
    }
    $json.values = $values
    Save-Json $tagPath $json
}

Write-Output "non-woodland expansion generated"
