$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$blockTextureDir = Join-Path $root "src\main\resources\assets\camowarfare\textures\block"
$itemTextureDir = Join-Path $root "src\main\resources\assets\camowarfare\textures\item"
New-Item -ItemType Directory -Force -Path $itemTextureDir | Out-Null

function Get-Color($hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($hex)
}

function Draw-PlateTexture {
    param(
        [string]$Path,
        [string]$BaseHex,
        [string]$LightHex,
        [string]$MidHex,
        [string]$DarkHex
    )

    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear((Get-Color $BaseHex))

    $brushLight = New-Object System.Drawing.SolidBrush (Get-Color $LightHex)
    $brushMid = New-Object System.Drawing.SolidBrush (Get-Color $MidHex)
    $brushDark = New-Object System.Drawing.SolidBrush (Get-Color $DarkHex)
    $brushShadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70, 0, 0, 0))

    $g.FillRectangle($brushMid, 1, 1, 14, 14)
    $g.FillRectangle($brushLight, 1, 1, 14, 2)
    $g.FillRectangle($brushLight, 1, 1, 2, 14)
    $g.FillRectangle($brushDark, 1, 13, 14, 2)
    $g.FillRectangle($brushDark, 13, 1, 2, 14)

    $g.FillRectangle($brushMid, 3, 3, 10, 10)
    $g.FillRectangle($brushLight, 3, 3, 10, 1)
    $g.FillRectangle($brushLight, 3, 3, 1, 10)
    $g.FillRectangle($brushDark, 3, 12, 10, 1)
    $g.FillRectangle($brushDark, 12, 3, 1, 10)

    foreach ($pt in @(@(2,2), @(12,2), @(2,12), @(12,12), @(7,7))) {
        $g.FillRectangle($brushDark, $pt[0], $pt[1], 2, 2)
        $g.FillRectangle($brushLight, $pt[0], $pt[1], 1, 1)
    }

    $g.FillRectangle($brushShadow, 5, 6, 6, 1)
    $g.FillRectangle($brushShadow, 6, 9, 5, 1)

    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $brushLight.Dispose()
    $brushMid.Dispose()
    $brushDark.Dispose()
    $brushShadow.Dispose()
    $bmp.Dispose()
}

function Draw-SlatTexture {
    param(
        [string]$Path,
        [string]$FrameHex,
        [string]$RailHex,
        [string]$HighlightHex,
        [string]$ShadowHex
    )

    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)

    $brushFrame = New-Object System.Drawing.SolidBrush (Get-Color $FrameHex)
    $brushRail = New-Object System.Drawing.SolidBrush (Get-Color $RailHex)
    $brushHighlight = New-Object System.Drawing.SolidBrush (Get-Color $HighlightHex)
    $brushShadow = New-Object System.Drawing.SolidBrush (Get-Color $ShadowHex)

    $g.FillRectangle($brushFrame, 0, 0, 16, 2)
    $g.FillRectangle($brushFrame, 0, 14, 16, 2)
    $g.FillRectangle($brushFrame, 0, 0, 2, 16)
    $g.FillRectangle($brushFrame, 14, 0, 2, 16)

    foreach ($x in @(2, 5, 8, 11)) {
        $g.FillRectangle($brushRail, $x, 2, 2, 12)
        $g.FillRectangle($brushHighlight, $x, 2, 1, 12)
        $g.FillRectangle($brushShadow, $x + 1, 2, 1, 12)
    }

    foreach ($x in @(2, 5, 8, 11)) {
        $g.FillRectangle($brushHighlight, $x, 1, 2, 1)
        $g.FillRectangle($brushHighlight, $x, 14, 2, 1)
    }

    foreach ($pt in @(@(1,1), @(13,1), @(1,13), @(13,13))) {
        $g.FillRectangle($brushHighlight, $pt[0], $pt[1], 2, 2)
        $g.FillRectangle($brushShadow, $pt[0] + 1, $pt[1] + 1, 1, 1)
    }

    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $brushFrame.Dispose()
    $brushRail.Dispose()
    $brushHighlight.Dispose()
    $brushShadow.Dispose()
    $bmp.Dispose()
}

function Draw-SectionTexture {
    param(
        [string]$Path,
        [string]$SourcePath,
        [string]$Label,
        [bool]$Title,
        [string]$BandHex
    )

    $source = [System.Drawing.Bitmap]::FromFile($SourcePath)
    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($source, (New-Object System.Drawing.Rectangle 0,0,16,16))

    $border = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(60,255,255,255))
    $band = New-Object System.Drawing.SolidBrush (Get-Color $BandHex)

    if ($Title) {
        $g.FillRectangle($band, 0, 0, 7, 16)
        $font = New-Object System.Drawing.Font "Microsoft YaHei UI", 6.2, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $g.DrawString($Label, $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF 0,0,7,16), $sf)
        $font.Dispose()
        $sf.Dispose()
    }

    $g.FillRectangle($border, 0, 0, 16, 1)
    $g.FillRectangle($border, 0, 15, 16, 1)
    $g.FillRectangle($border, 0, 0, 1, 16)
    $g.FillRectangle($border, 15, 0, 1, 16)

    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $border.Dispose()
    $band.Dispose()
    $bmp.Dispose()
    $source.Dispose()
}

Draw-PlateTexture (Join-Path $blockTextureDir "armor_plate_block.png") "#A7A9A6" "#D5D7D4" "#BFC2BE" "#747874"
Draw-PlateTexture (Join-Path $blockTextureDir "add_on_armor_plate_block.png") "#888C92" "#B8BEC5" "#9EA4AC" "#5E646C"
Draw-PlateTexture (Join-Path $blockTextureDir "add_on_armor_plate_military_green_block.png") "#6A725C" "#9DA889" "#7D876E" "#454D3C"
Draw-PlateTexture (Join-Path $blockTextureDir "add_on_armor_plate_desert_sand_block.png") "#A89370" "#D0BD96" "#BDAA84" "#726046"
Draw-PlateTexture (Join-Path $blockTextureDir "add_on_armor_plate_bluegray_block.png") "#74808D" "#A9B7C7" "#8793A0" "#4E5965"
Draw-PlateTexture (Join-Path $blockTextureDir "add_on_armor_plate_night_black_block.png") "#4A4E54" "#7C838C" "#5E646B" "#262A2F"

Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_block.png") "#666B73" "#8A9098" "#B5BCC6" "#40454C"
Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_military_green_block.png") "#58604F" "#748067" "#A0AB8D" "#353C2F"
Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_desert_sand_block.png") "#8E7D60" "#AA9979" "#D3C19D" "#5C4F3C"
Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_bluegray_block.png") "#5D6977" "#7B8898" "#AAB7C6" "#39424C"
Draw-SlatTexture (Join-Path $blockTextureDir "slat_armor_night_black_block.png") "#40444A" "#5A6069" "#878F99" "#23262B"

$sections = @(
    @{ Id = "attachments"; Label = "附件"; Source = (Join-Path $blockTextureDir "add_on_armor_plate_military_green_block.png"); Band = "#3E454B" },
    @{ Id = "woodland"; Label = "林地"; Source = (Join-Path $blockTextureDir "woodland_macro\\a_atlas.png"); Band = "#445137" },
    @{ Id = "desert"; Label = "沙地"; Source = (Join-Path $blockTextureDir "nato_desert\\a_atlas.png"); Band = "#6E5D42" },
    @{ Id = "digital"; Label = "数码"; Source = (Join-Path $blockTextureDir "woodland_digital\\a_atlas.png"); Band = "#3C4D56" },
    @{ Id = "solid"; Label = "单色"; Source = (Join-Path $blockTextureDir "solid_military_green\\a_atlas.png"); Band = "#4A545A" },
    @{ Id = "special"; Label = "特装"; Source = (Join-Path $blockTextureDir "naval_bluegray\\a_atlas.png"); Band = "#46474D" }
)

foreach ($section in $sections) {
    Draw-SectionTexture (Join-Path $itemTextureDir ("section_" + $section.Id + "_title.png")) $section.Source $section.Label $true $section.Band
    Draw-SectionTexture (Join-Path $itemTextureDir ("section_" + $section.Id + "_fill.png")) $section.Source $section.Label $false $section.Band
}

Write-Output "visual assets refreshed"
