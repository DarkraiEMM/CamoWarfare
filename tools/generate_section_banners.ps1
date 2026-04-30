$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$itemTextureDir = Join-Path $root "src\main\resources\assets\camowarfare\textures\item"
$previewDir = Join-Path $root "preview\section_banners"
New-Item -ItemType Directory -Force -Path $itemTextureDir | Out-Null
New-Item -ItemType Directory -Force -Path $previewDir | Out-Null

$sliceSize = 512
$sliceCount = 9
$bannerWidth = $sliceSize * $sliceCount
$bannerHeight = $sliceSize

function Get-Color($hex) {
    [System.Drawing.ColorTranslator]::FromHtml($hex)
}

function New-MetalBanner {
    param(
        [string]$OutBaseName,
        [string]$PrimaryHex,
        [string]$SecondaryHex
    )

    $banner = New-Object System.Drawing.Bitmap $bannerWidth, $bannerHeight
    $g = [System.Drawing.Graphics]::FromImage($banner)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

    $primary = Get-Color $PrimaryHex
    $secondary = Get-Color $SecondaryHex
    $light = [System.Drawing.Color]::FromArgb(90, 255, 255, 255)
    $shadow = [System.Drawing.Color]::FromArgb(90, 0, 0, 0)

    $g.Clear($primary)

    for ($x = 0; $x -lt $bannerWidth; $x += 96) {
        $plateBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, [Math]::Min(255, $secondary.R + 10), [Math]::Min(255, $secondary.G + 10), [Math]::Min(255, $secondary.B + 10)))
        $g.FillRectangle($plateBrush, $x, 56, 88, $bannerHeight - 112)
        $plateBrush.Dispose()

        $g.FillRectangle((New-Object System.Drawing.SolidBrush $light), $x, 56, 88, 8)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush $shadow), $x, $bannerHeight - 64, 88, 8)

        foreach ($y in @(96, ($bannerHeight - 112))) {
            foreach ($dx in @(16, 72)) {
                $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(200, 215, 215, 215))), $x + $dx - 8, $y - 8, 16, 16)
                $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(100, 80, 80, 80))), $x + $dx - 4, $y - 4, 8, 8)
            }
        }
    }

    $g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70, 255, 255, 255))), 0, 0, $bannerWidth, 10)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(110, 0, 0, 0))), 0, $bannerHeight - 10, $bannerWidth, 10)

    Save-BannerSlices -Banner $banner -OutBaseName $OutBaseName
    $banner.Save((Join-Path $previewDir ("section_" + $OutBaseName + "_full.png")), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $banner.Dispose()
}

function New-CamoBanner {
    param(
        [string]$OutBaseName,
        [string]$SourcePath,
        [string]$TintHex,
        [string]$EdgeHex
    )

    $source = [System.Drawing.Bitmap]::FromFile($SourcePath)
    $banner = New-Object System.Drawing.Bitmap $bannerWidth, $bannerHeight
    $g = [System.Drawing.Graphics]::FromImage($banner)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

    $tileSize = 256
    for ($x = 0; $x -lt $bannerWidth; $x += $tileSize) {
        for ($y = 0; $y -lt $bannerHeight; $y += $tileSize) {
            $srcX = (($x / 32) + ($y / 64)) % [Math]::Max(1, $source.Width - 32)
            $srcY = (($x / 48) + ($y / 24)) % [Math]::Max(1, $source.Height - 32)
            $srcRect = New-Object System.Drawing.Rectangle $srcX, $srcY, ([Math]::Min(32, $source.Width)), ([Math]::Min(32, $source.Height))
            $dstRect = New-Object System.Drawing.Rectangle $x, $y, $tileSize, $tileSize
            $g.DrawImage($source, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
        }
    }

    $tintColor = Get-Color $TintHex
    $edgeColor = Get-Color $EdgeHex
    $tint = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(54, $tintColor.R, $tintColor.G, $tintColor.B))
    $edge = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, $edgeColor.R, $edgeColor.G, $edgeColor.B))
    $shine = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(64, 255, 255, 255))
    $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(96, 0, 0, 0))

    $g.FillRectangle($tint, 0, 0, $bannerWidth, $bannerHeight)
    $g.FillRectangle($shine, 0, 0, $bannerWidth, 8)
    $g.FillRectangle($shadow, 0, $bannerHeight - 12, $bannerWidth, 12)
    $g.FillRectangle($edge, 0, 18, $bannerWidth, 6)
    $g.FillRectangle($edge, 0, $bannerHeight - 24, $bannerWidth, 6)

    for ($x = 384; $x -lt $bannerWidth; $x += 768) {
        $g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(50, 255, 255, 255))), $x, 0, 10, $bannerHeight)
    }

    Save-BannerSlices -Banner $banner -OutBaseName $OutBaseName
    $banner.Save((Join-Path $previewDir ("section_" + $OutBaseName + "_full.png")), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $banner.Dispose()
    $source.Dispose()
    $tint.Dispose()
    $edge.Dispose()
    $shine.Dispose()
    $shadow.Dispose()
}

function Save-BannerSlices {
    param(
        [System.Drawing.Bitmap]$Banner,
        [string]$OutBaseName
    )

    for ($i = 0; $i -lt $sliceCount; $i++) {
        $slice = New-Object System.Drawing.Bitmap $sliceSize, $sliceSize
        $g = [System.Drawing.Graphics]::FromImage($slice)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        $srcRect = New-Object System.Drawing.Rectangle ($i * $sliceSize), 0, $sliceSize, $sliceSize
        $dstRect = New-Object System.Drawing.Rectangle 0, 0, $sliceSize, $sliceSize
        $g.DrawImage($Banner, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
        $name = if ($i -eq 0) { "section_${OutBaseName}_title.png" } else { "section_${OutBaseName}_fill_${i}.png" }
        $slice.Save((Join-Path $itemTextureDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose()
        $slice.Dispose()
    }
}

New-MetalBanner -OutBaseName "attachments" -PrimaryHex "#58626B" -SecondaryHex "#8A959D"
New-CamoBanner -OutBaseName "woodland" -SourcePath (Join-Path $root "src\main\resources\assets\camowarfare\textures\block\woodland_macro\a_atlas.png") -TintHex "#314327" -EdgeHex "#76885E"
New-CamoBanner -OutBaseName "mountain" -SourcePath (Join-Path $root "src\main\resources\assets\camowarfare\textures\block\pla_mountain\a_atlas.png") -TintHex "#495040" -EdgeHex "#8D8E73"
New-CamoBanner -OutBaseName "desert" -SourcePath (Join-Path $root "src\main\resources\assets\camowarfare\textures\block\nato_desert\a_atlas.png") -TintHex "#775C36" -EdgeHex "#B69B6B"
New-CamoBanner -OutBaseName "snow" -SourcePath (Join-Path $root "src\main\resources\assets\camowarfare\textures\block\winter_whitewash\a_atlas.png") -TintHex "#8B99A2" -EdgeHex "#E0E7EC"
New-CamoBanner -OutBaseName "night" -SourcePath (Join-Path $root "src\main\resources\assets\camowarfare\textures\block\black_night\a_atlas.png") -TintHex "#20252B" -EdgeHex "#4A525C"
New-CamoBanner -OutBaseName "naval" -SourcePath (Join-Path $root "src\main\resources\assets\camowarfare\textures\block\naval_bluegray\a_atlas.png") -TintHex "#31475E" -EdgeHex "#7B92A3"
New-CamoBanner -OutBaseName "urban" -SourcePath (Join-Path $root "src\main\resources\assets\camowarfare\textures\block\urban_digital\a_atlas.png") -TintHex "#454A4F" -EdgeHex "#8D949B"
New-CamoBanner -OutBaseName "solid" -SourcePath (Join-Path $root "src\main\resources\assets\camowarfare\textures\block\solid_military_green\a_atlas.png") -TintHex "#556048" -EdgeHex "#9EAF87"

Write-Output "section banners regenerated at 4608x512 and sliced to 512x512"
