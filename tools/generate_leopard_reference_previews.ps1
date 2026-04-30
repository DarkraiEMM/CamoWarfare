$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$previewRoot = Join-Path $projectRoot "preview"

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
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

function ConvertTo-Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function Fill-WrappedPolygon(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Color]$Color,
    [System.Drawing.PointF[]]$Points,
    [int]$TileSize
) {
    $brush = [System.Drawing.SolidBrush]::new($Color)
    try {
        foreach ($offsetX in @(-$TileSize, 0, $TileSize)) {
            foreach ($offsetY in @(-$TileSize, 0, $TileSize)) {
                $shifted = foreach ($point in $Points) {
                    [System.Drawing.PointF]::new($point.X + $offsetX, $point.Y + $offsetY)
                }
                $Graphics.FillPolygon($brush, $shifted)
            }
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
    $points = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    $angleOffset = $Random.NextDouble() * [Math]::PI * 2.0

    for ($index = 0; $index -lt $PointCount; $index++) {
        $angle = $angleOffset + (($index / [double]$PointCount) * [Math]::PI * 2.0)
        $jitterX = 0.72 + ($Random.NextDouble() * 0.52)
        $jitterY = 0.72 + ($Random.NextDouble() * 0.52)
        $x = $CenterX + ([Math]::Cos($angle) * $RadiusX * $jitterX)
        $y = $CenterY + ([Math]::Sin($angle) * $RadiusY * $jitterY)
        $points.Add([System.Drawing.PointF]::new([float]$x, [float]$y))
    }

    return $points.ToArray()
}

function Add-PatchLayer(
    [System.Drawing.Graphics]$Graphics,
    [System.Random]$Random,
    [System.Drawing.Color]$Color,
    [int]$TileSize,
    [int]$Count,
    [double]$RadiusMin,
    [double]$RadiusMax,
    [double]$AspectMin,
    [double]$AspectMax
) {
    for ($i = 0; $i -lt $Count; $i++) {
        $centerX = $Random.NextDouble() * $TileSize
        $centerY = $Random.NextDouble() * $TileSize
        $radius = $RadiusMin + ($Random.NextDouble() * ($RadiusMax - $RadiusMin))
        $aspect = $AspectMin + ($Random.NextDouble() * ($AspectMax - $AspectMin))

        if ($Random.NextDouble() -gt 0.5) {
            $radiusX = $radius * $aspect
            $radiusY = $radius
        }
        else {
            $radiusX = $radius
            $radiusY = $radius * $aspect
        }

        $points = New-IrregularPatch `
            -Random $Random `
            -CenterX $centerX `
            -CenterY $centerY `
            -RadiusX $radiusX `
            -RadiusY $radiusY `
            -PointCount (8 + $Random.Next(6))

        Fill-WrappedPolygon -Graphics $Graphics -Color $Color -Points $points -TileSize $TileSize
    }
}

function Draw-LeopardInspiredPattern(
    [System.Drawing.Bitmap]$Bitmap,
    [string]$Seed
) {
    $random = [System.Random]::new([Math]::Abs($Seed.GetHashCode()))
    $base = ConvertTo-Color "#59624A"
    $lightOlive = ConvertTo-Color "#73815D"
    $brown = ConvertTo-Color "#705E43"
    $darkOlive = ConvertTo-Color "#303528"

    Use-Graphics $Bitmap {
        param($Graphics)
        $Graphics.Clear($base)

        Add-PatchLayer -Graphics $Graphics -Random $random -Color $lightOlive -TileSize 256 -Count 4 -RadiusMin 34 -RadiusMax 52 -AspectMin 1.1 -AspectMax 1.8
        Add-PatchLayer -Graphics $Graphics -Random $random -Color $brown -TileSize 256 -Count 4 -RadiusMin 30 -RadiusMax 48 -AspectMin 1.0 -AspectMax 1.7
        Add-PatchLayer -Graphics $Graphics -Random $random -Color $darkOlive -TileSize 256 -Count 3 -RadiusMin 28 -RadiusMax 44 -AspectMin 1.1 -AspectMax 1.9
    }
}

function Save-Png([System.Drawing.Bitmap]$Bitmap, [string]$Path) {
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

Ensure-Directory $previewRoot

$candidates = @(
    @{ Name = "leopard_reference_candidate_1"; Seed = "leopard-reference-1" },
    @{ Name = "leopard_reference_candidate_2"; Seed = "leopard-reference-2" },
    @{ Name = "leopard_reference_candidate_3"; Seed = "leopard-reference-3" }
)

$saved = New-Object System.Collections.Generic.List[string]

foreach ($candidate in $candidates) {
    $bitmap = New-Bitmap 256 256
    try {
        Draw-LeopardInspiredPattern -Bitmap $bitmap -Seed $candidate.Seed
        $path = Join-Path $previewRoot ($candidate.Name + ".png")
        Save-Png -Bitmap $bitmap -Path $path
        $saved.Add($path)
    }
    finally {
        $bitmap.Dispose()
    }
}

$sheet = New-Bitmap 800 280
try {
    Use-Graphics $sheet {
        param($Graphics)
        $Graphics.Clear((ConvertTo-Color "#1F231D"))
        $font = [System.Drawing.Font]::new("Microsoft YaHei UI", 14, [System.Drawing.FontStyle]::Regular)
        $titleFont = [System.Drawing.Font]::new("Microsoft YaHei UI", 18, [System.Drawing.FontStyle]::Bold)
        $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 226, 230, 220))
        try {
            $Graphics.DrawString("Leopard 2A7 Woodland Macro Preview", $titleFont, $textBrush, 18, 14)
            $x = 18
            $index = 1
            foreach ($path in $saved) {
                $image = [System.Drawing.Image]::FromFile($path)
                try {
                    $Graphics.DrawImage($image, $x, 48, 240, 240)
                    $Graphics.DrawString("方案 $index", $font, $textBrush, $x, 252)
                }
                finally {
                    $image.Dispose()
                }
                $x += 258
                $index++
            }
        }
        finally {
            $textBrush.Dispose()
            $font.Dispose()
            $titleFont.Dispose()
        }
    }

    Save-Png -Bitmap $sheet -Path (Join-Path $previewRoot "leopard_reference_candidates_sheet.png")
}
finally {
    $sheet.Dispose()
}
