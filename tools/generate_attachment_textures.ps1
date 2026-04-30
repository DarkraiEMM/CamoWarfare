$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$blockTextureDir = Join-Path $root "src\main\resources\assets\camowarfare\textures\block"

function Get-Color($hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($hex)
}

function Write-Png($bmp, $path) {
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function Get-TextureBitmap {
    param(
        [string]$RelativePath
    )

    $fullPath = Join-Path $blockTextureDir $RelativePath
    if (-not (Test-Path $fullPath)) {
        throw "Missing source texture: $fullPath"
    }

    $source = [System.Drawing.Bitmap]::FromFile($fullPath)
    $scaled = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($scaled)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($source, 0, 0, 16, 16)
    $g.Dispose()
    $source.Dispose()
    return $scaled
}

function Draw-AddOnTexture {
    param(
        [string]$Path,
        [string]$BaseHex,
        [string]$LightHex,
        [string]$MidHex,
        [string]$DarkHex,
        [string]$SourceTexture = $null
    )

    $bmp = if ($SourceTexture) { Get-TextureBitmap $SourceTexture } else { New-Object System.Drawing.Bitmap 16, 16 }
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    if (-not $SourceTexture) {
        $g.Clear((Get-Color $BaseHex))
    }

    $base = New-Object System.Drawing.SolidBrush (Get-Color $BaseHex)
    $light = New-Object System.Drawing.SolidBrush (Get-Color $LightHex)
    $mid = New-Object System.Drawing.SolidBrush (Get-Color $MidHex)
    $dark = New-Object System.Drawing.SolidBrush (Get-Color $DarkHex)
    $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(45, 0, 0, 0))

    $g.FillRectangle($base, 0, 0, 16, 16)

    # Backing plate: broad, subtle, and close to hull color.
    $g.FillRectangle($mid, 0, 2, 16, 12)
    $g.FillRectangle($light, 0, 2, 16, 1)
    $g.FillRectangle($light, 0, 2, 1, 12)
    $g.FillRectangle($dark, 0, 13, 16, 1)
    $g.FillRectangle($dark, 15, 2, 1, 12)

    # Front ERA cassette: slightly raised but not a separate brick.
    $g.FillRectangle($mid, 1, 3, 14, 10)
    $g.FillRectangle($light, 1, 3, 14, 1)
    $g.FillRectangle($light, 1, 3, 1, 10)
    $g.FillRectangle($dark, 1, 12, 14, 1)
    $g.FillRectangle($dark, 14, 3, 1, 10)

    # Shallow seam and fasteners to suggest ERA mounting without breaking the paint.
    $g.FillRectangle($shadow, 3, 7, 10, 1)
    foreach ($pt in @(@(3,5), @(11,5), @(3,10), @(11,10))) {
        $g.FillRectangle($dark, $pt[0], $pt[1], 1, 1)
        $g.FillRectangle($light, $pt[0], $pt[1], 1, 1)
    }

    $g.Dispose()
    $base.Dispose()
    $light.Dispose()
    $mid.Dispose()
    $dark.Dispose()
    $shadow.Dispose()
    Write-Png $bmp $Path
}

function Draw-SlatTexture {
    param(
        [string]$Path,
        [string]$BaseHex,
        [string]$LightHex,
        [string]$DarkHex,
        [string]$SourceTexture = $null
    )

    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)

    $base = New-Object System.Drawing.SolidBrush (Get-Color $BaseHex)
    $light = New-Object System.Drawing.SolidBrush (Get-Color $LightHex)
    $dark = New-Object System.Drawing.SolidBrush (Get-Color $DarkHex)
    $textureBmp = $null

    if ($SourceTexture) {
        $textureBmp = Get-TextureBitmap $SourceTexture
    }

    foreach ($rect in @(
        @(0,1,16,2), @(0,13,16,2),
        @(0,1,1,14), @(15,1,1,14)
    )) {
        if ($textureBmp) {
            $g.DrawImage($textureBmp, [System.Drawing.Rectangle]::new($rect[0], $rect[1], $rect[2], $rect[3]), [System.Drawing.Rectangle]::new($rect[0], $rect[1], $rect[2], $rect[3]), [System.Drawing.GraphicsUnit]::Pixel)
        } else {
            $g.FillRectangle($base, $rect[0], $rect[1], $rect[2], $rect[3])
        }
    }

    foreach ($x in @(3,6,9,12)) {
        if ($textureBmp) {
            $g.DrawImage($textureBmp, [System.Drawing.Rectangle]::new($x, 2, 1, 11), [System.Drawing.Rectangle]::new($x, 2, 1, 11), [System.Drawing.GraphicsUnit]::Pixel)
        } else {
            $g.FillRectangle($base, $x, 2, 1, 11)
        }
    }

    # Match the slimmer bars but thicker depth of an attached iron-bar style cage.
    $g.FillRectangle($light, 0, 1, 16, 1)
    $g.FillRectangle($dark, 0, 14, 16, 1)
    $g.FillRectangle($light, 0, 1, 1, 10)
    $g.FillRectangle($light, 15, 1, 1, 10)
    $g.FillRectangle($dark, 0, 11, 1, 4)
    $g.FillRectangle($dark, 15, 11, 1, 4)

    foreach ($x in @(3,6,9,12)) {
        $g.FillRectangle($light, $x, 2, 1, 5)
        $g.FillRectangle($dark, $x, 7, 1, 6)
    }

    $g.Dispose()
    $base.Dispose()
    $light.Dispose()
    $dark.Dispose()
    if ($textureBmp) { $textureBmp.Dispose() }
    Write-Png $bmp $Path
}

Draw-AddOnTexture (Join-Path $blockTextureDir "add_on_armor_plate_block.png") "#7C8288" "#A2A9B0" "#878E95" "#545A61"
Draw-AddOnTexture (Join-Path $blockTextureDir "add_on_armor_plate_military_green_block.png") "#697457" "#8A9870" "#73805F" "#465039" "solid_military_green\a_atlas.png"
Draw-AddOnTexture (Join-Path $blockTextureDir "add_on_armor_plate_desert_sand_block.png") "#A68E62" "#C6AE80" "#B2986B" "#726045" "solid_desert_sand\a_atlas.png"
Draw-AddOnTexture (Join-Path $blockTextureDir "add_on_armor_plate_bluegray_block.png") "#65788C" "#8499AE" "#708398" "#425465" "solid_bluegray\a_atlas.png"
Draw-AddOnTexture (Join-Path $blockTextureDir "add_on_armor_plate_night_black_block.png") "#353B43" "#56606B" "#414850" "#21262D" "solid_night_black\a_atlas.png"

Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_block.png") "#737A82" "#B7C0CA" "#434A52"
Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_military_green_block.png") "#5F6A4F" "#98A685" "#33402B" "solid_military_green\a_atlas.png"
Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_desert_sand_block.png") "#927D5A" "#D0BD93" "#5A4D38" "solid_desert_sand\a_atlas.png"
Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_bluegray_block.png") "#5F7185" "#A6B7C8" "#394756" "solid_bluegray\a_atlas.png"
Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_night_black_block.png") "#383E46" "#7A8490" "#1E232A" "solid_night_black\a_atlas.png"

Write-Output "attachment textures refreshed"
