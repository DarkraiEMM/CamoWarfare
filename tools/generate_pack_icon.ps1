$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $root "src\main\resources\pack.png"

$size = 256
$bitmap = [System.Drawing.Bitmap]::new($size, $size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::FromArgb(24, 28, 24))

    $bg = [System.Drawing.Rectangle]::new(0, 0, $size, $size)
    $backBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Point]::new(0, 0),
        [System.Drawing.Point]::new($size, $size),
        [System.Drawing.Color]::FromArgb(68, 84, 65),
        [System.Drawing.Color]::FromArgb(43, 53, 43)
    )
    $graphics.FillRectangle($backBrush, $bg)
    $backBrush.Dispose()

    $camoBrushes = @(
        [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(106, 125, 92)),
        [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(83, 97, 71)),
        [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(134, 116, 76)),
        [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(48, 54, 43))
    )

    $camoRects = @(
        @(8, 14, 84, 48, 0),
        @(76, 0, 92, 52, 1),
        @(154, 20, 94, 46, 2),
        @(6, 70, 70, 58, 3),
        @(54, 62, 106, 62, 0),
        @(146, 74, 102, 52, 1),
        @(16, 132, 88, 48, 2),
        @(84, 124, 88, 62, 3),
        @(160, 132, 78, 60, 0),
        @(14, 188, 86, 52, 1),
        @(92, 194, 82, 42, 2),
        @(164, 198, 74, 40, 3)
    )

    foreach ($entry in $camoRects) {
        $graphics.FillRectangle($camoBrushes[$entry[4]], $entry[0], $entry[1], $entry[2], $entry[3])
    }

    foreach ($brush in $camoBrushes) { $brush.Dispose() }

    $overlayPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(42, 255, 255, 255), 2)
    for ($i = 18; $i -lt $size; $i += 24) {
        $graphics.DrawLine($overlayPen, $i, 0, 0, $i)
        $graphics.DrawLine($overlayPen, $size, $i, $i, $size)
    }
    $overlayPen.Dispose()

    $hullBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 235, 236, 230))
    $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(70, 0, 0, 0))
    $accentBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(190, 74, 92, 72))

    $body = [System.Drawing.Point[]]@(
        [System.Drawing.Point]::new(48, 150),
        [System.Drawing.Point]::new(158, 150),
        [System.Drawing.Point]::new(184, 132),
        [System.Drawing.Point]::new(206, 132),
        [System.Drawing.Point]::new(212, 150),
        [System.Drawing.Point]::new(224, 150),
        [System.Drawing.Point]::new(224, 174),
        [System.Drawing.Point]::new(40, 174)
    )
    $turret = [System.Drawing.Point[]]@(
        [System.Drawing.Point]::new(94, 112),
        [System.Drawing.Point]::new(154, 112),
        [System.Drawing.Point]::new(170, 124),
        [System.Drawing.Point]::new(162, 138),
        [System.Drawing.Point]::new(98, 138),
        [System.Drawing.Point]::new(84, 128)
    )

    $graphics.FillPolygon($shadowBrush, ($body | ForEach-Object { [System.Drawing.Point]::new($_.X + 5, $_.Y + 6) }))
    $graphics.FillPolygon($shadowBrush, ($turret | ForEach-Object { [System.Drawing.Point]::new($_.X + 5, $_.Y + 6) }))
    $graphics.FillPolygon($hullBrush, $body)
    $graphics.FillPolygon($hullBrush, $turret)
    $graphics.FillRectangle($hullBrush, 158, 118, 54, 8)

    $graphics.FillRectangle($accentBrush, 56, 158, 156, 6)
    $graphics.FillRectangle($accentBrush, 94, 120, 62, 6)
    $graphics.FillEllipse($accentBrush, 60, 176, 28, 28)
    $graphics.FillEllipse($accentBrush, 104, 176, 28, 28)
    $graphics.FillEllipse($accentBrush, 148, 176, 28, 28)
    $graphics.FillEllipse($accentBrush, 192, 176, 28, 28)

    $shadowBrush.Dispose()
    $accentBrush.Dispose()

    $fontFamily = [System.Drawing.FontFamily]::GenericSansSerif
    $cwFont = [System.Drawing.Font]::new($fontFamily, 44, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $subFont = [System.Drawing.Font]::new($fontFamily, 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(246, 248, 244))
    $subBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(214, 220, 208))

    $graphics.DrawString("CW", $cwFont, $textBrush, 22, 18)
    $graphics.DrawString("CAMO BLOCKS", $subFont, $subBrush, 24, 68)

    $cwFont.Dispose()
    $subFont.Dispose()
    $textBrush.Dispose()
    $subBrush.Dispose()
    $hullBrush.Dispose()

    $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(200, 232, 238, 228), 4)
    $graphics.DrawRectangle($borderPen, 6, 6, $size - 12, $size - 12)
    $borderPen.Dispose()

    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}

Write-Output "Generated pack icon at $outputPath"
