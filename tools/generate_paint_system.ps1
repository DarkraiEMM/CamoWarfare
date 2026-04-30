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
$langRoot = Join-Path $assetsRoot "lang"
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

function Scale16([int]$value, [int]$size) {
    return [int][Math]::Round(($value / 16.0) * $size)
}

function Fill-Rect($graphics, $brush, [int]$x16, [int]$y16, [int]$w16, [int]$h16, [int]$size) {
    $graphics.FillRectangle($brush, (Scale16 $x16 $size), (Scale16 $y16 $size), (Scale16 $w16 $size), (Scale16 $h16 $size))
}

function Draw-NumberPaint($bmp, $variant, $panelColor, $markColor) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $size = $bmp.Width
    $panelBrush = New-Object System.Drawing.SolidBrush $panelColor
    $markBrush = New-Object System.Drawing.SolidBrush $markColor

    switch ($variant) {
        "a" {
            Fill-Rect $g $panelBrush 2 3 7 5 $size
            Fill-Rect $g $markBrush 3 4 1 3 $size
            Fill-Rect $g $markBrush 5 4 1 3 $size
            Fill-Rect $g $markBrush 7 4 1 3 $size
        }
        "b" {
            Fill-Rect $g $panelBrush 7 2 7 5 $size
            Fill-Rect $g $markBrush 8 3 5 1 $size
            Fill-Rect $g $markBrush 8 5 5 1 $size
        }
        "c" {
            Fill-Rect $g $panelBrush 2 9 7 4 $size
            Fill-Rect $g $markBrush 3 10 4 1 $size
            Fill-Rect $g $markBrush 6 10 1 2 $size
        }
        "d" {
            Fill-Rect $g $panelBrush 8 9 5 4 $size
            Fill-Rect $g $markBrush 9 10 3 1 $size
            Fill-Rect $g $markBrush 10 9 1 3 $size
        }
    }

    $g.Dispose()
    $panelBrush.Dispose()
    $markBrush.Dispose()
}

function Draw-StripePaint($bmp, $variant, $stripeColor, $accentColor) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $size = $bmp.Width
    $stripeBrush = New-Object System.Drawing.SolidBrush $stripeColor
    $accentBrush = New-Object System.Drawing.SolidBrush $accentColor

    switch ($variant) {
        "a" {
            Fill-Rect $g $stripeBrush 0 4 16 2 $size
            Fill-Rect $g $accentBrush 0 7 16 1 $size
        }
        "b" {
            Fill-Rect $g $stripeBrush 0 6 16 2 $size
            Fill-Rect $g $accentBrush 0 3 16 1 $size
        }
        "c" {
            Fill-Rect $g $stripeBrush 3 0 2 16 $size
            Fill-Rect $g $accentBrush 7 0 1 16 $size
        }
        "d" {
            Fill-Rect $g $stripeBrush 11 0 2 16 $size
            Fill-Rect $g $accentBrush 8 0 1 16 $size
        }
    }

    $g.Dispose()
    $stripeBrush.Dispose()
    $accentBrush.Dispose()
}

$families = @(
    @{
        Id = "solid_military_green_number"
        EnLabel = "Military Green Number Paint"
        Source = "solid_military_green"
        Kind = "number"
        Panel = [System.Drawing.ColorTranslator]::FromHtml("#D7D2BA")
        Mark = [System.Drawing.ColorTranslator]::FromHtml("#5D644A")
    },
    @{
        Id = "solid_military_green_stripe"
        EnLabel = "Military Green Recognition Stripe"
        Source = "solid_military_green"
        Kind = "stripe"
        Panel = [System.Drawing.ColorTranslator]::FromHtml("#C6C0A6")
        Mark = [System.Drawing.ColorTranslator]::FromHtml("#6F775B")
    },
    @{
        Id = "solid_desert_sand_number"
        EnLabel = "Desert Number Paint"
        Source = "solid_desert_sand"
        Kind = "number"
        Panel = [System.Drawing.ColorTranslator]::FromHtml("#8A6E43")
        Mark = [System.Drawing.ColorTranslator]::FromHtml("#E1CFA6")
    },
    @{
        Id = "solid_night_black_lowvis_number"
        EnLabel = "Night Low-Visibility Number Paint"
        Source = "solid_night_black"
        Kind = "number"
        Panel = [System.Drawing.ColorTranslator]::FromHtml("#4E535A")
        Mark = [System.Drawing.ColorTranslator]::FromHtml("#2A2E33")
    }
)

foreach ($family in $families) {
    $familyTextureDir = Join-Path $blockTextureRoot $family.Id
    Ensure-Dir $familyTextureDir

    foreach ($variant in "a","b","c","d") {
        $src = Join-Path (Join-Path $blockTextureRoot $family.Source) ($variant + "_atlas.png")
        $sampleTarget = Join-Path $familyTextureDir ($variant + "_atlas.png")
        $mainTarget = Join-Path $familyTextureDir ($variant + ".png")

        $bmp = Load-Bitmap $src
        try {
            if ($family.Kind -eq "number") {
                Draw-NumberPaint $bmp $variant $family.Panel $family.Mark
            } else {
                Draw-StripePaint $bmp $variant $family.Panel $family.Mark
            }
            $bmp.Save($sampleTarget, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Save($mainTarget, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bmp.Dispose()
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
            parent = "minecraft:block/cube_all"
            render_type = "minecraft:solid"
            textures = @{
                all = "camowarfare:block/$($family.Id)/${variant}_atlas"
                particle = "camowarfare:block/$($family.Id)/${variant}_atlas"
            }
        }

        Save-Json (Join-Path $itemModelRoot ($blockId + ".json")) @{
            parent = "camowarfare:block/$blockId"
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

$langFiles = @(
    (Join-Path $langRoot "en_us.json"),
    (Join-Path $langRoot "ru_ru.json"),
    (Join-Path $langRoot "de_de.json"),
    (Join-Path $langRoot "fr_fr.json")
)

foreach ($langPath in $langFiles) {
    $json = Get-Content -Raw -Path $langPath | ConvertFrom-Json
    foreach ($family in $families) {
        foreach ($variant in "A","B","C","D") {
            $key = "block.camowarfare.$($family.Id)_$($variant.ToLower())_block"
            $value = "$($family.EnLabel) $variant"
            Add-Member -InputObject $json -NotePropertyName $key -NotePropertyValue $value -Force
        }
    }
    Save-Json $langPath $json
}

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

Write-Output "paint system generated"
