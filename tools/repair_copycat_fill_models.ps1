$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $root "src\main\resources\assets\camowarfare"
$blockModelsRoot = Join-Path $assetsRoot "models\block"
$itemModelsRoot = Join-Path $assetsRoot "models\item"
$texturesRoot = Join-Path $assetsRoot "textures"

function Save-JsonFile([string]$Path, $Data) {
    $json = $Data | ConvertTo-Json -Depth 20
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, $encoding)
}

function Resize-Bitmap(
    [System.Drawing.Bitmap]$Source,
    [int]$Width,
    [int]$Height
) {
    $resized = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($resized)
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.DrawImage($Source, [System.Drawing.Rectangle]::new(0, 0, $Width, $Height))
        return $resized
    }
    finally {
        $graphics.Dispose()
    }
}

function Draw-TiledAppearanceTexture(
    [System.Drawing.Bitmap]$Source,
    [string]$DestinationPath
) {
    $tileSize = 32
    $targetSize = 128
    $tile = Resize-Bitmap $Source $tileSize $tileSize
    $output = [System.Drawing.Bitmap]::new($targetSize, $targetSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
        $graphics.Clear([System.Drawing.Color]::Transparent)

        for ($row = 0; $row -lt 4; $row++) {
            for ($col = 0; $col -lt 4; $col++) {
                $destRect = [System.Drawing.Rectangle]::new($col * $tileSize, $row * $tileSize, $tileSize, $tileSize)
                $graphics.ResetTransform()

                if (($col % 2) -eq 1 -or ($row % 2) -eq 1) {
                    $scaleX = if (($col % 2) -eq 1) { -1 } else { 1 }
                    $scaleY = if (($row % 2) -eq 1) { -1 } else { 1 }
                    $translateX = if ($scaleX -eq -1) { $destRect.X + $destRect.Width } else { $destRect.X }
                    $translateY = if ($scaleY -eq -1) { $destRect.Y + $destRect.Height } else { $destRect.Y }
                    $graphics.TranslateTransform($translateX, $translateY)
                    $graphics.ScaleTransform($scaleX, $scaleY)
                    $graphics.DrawImage($tile, 0, 0, $tileSize, $tileSize)
                } else {
                    $graphics.DrawImage($tile, $destRect)
                }
            }
        }

        $output.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $output.Dispose()
        $tile.Dispose()
    }
}

function Get-TextureFilePath([string]$ResourcePath) {
    if ([string]::IsNullOrWhiteSpace($ResourcePath)) {
        return $null
    }
    if (-not $ResourcePath.StartsWith("camowarfare:")) {
        return $null
    }
    $relative = $ResourcePath.Substring("camowarfare:".Length).Replace("/", "\") + ".png"
    return Join-Path $texturesRoot $relative
}

function Ensure-FillSafeMasks([string]$ResourcePath) {
    $sourcePath = Get-TextureFilePath $ResourcePath
    if (-not $sourcePath -or -not (Test-Path $sourcePath)) {
        return $false
    }

    $directory = [System.IO.Path]::GetDirectoryName($sourcePath)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($sourcePath)
    for ($mask = 0; $mask -lt 16; $mask++) {
        $destination = Join-Path $directory ($baseName + "_m" + $mask + ".png")
        Copy-Item -LiteralPath $sourcePath -Destination $destination -Force
    }
    return $true
}

function New-ConnectedBlockModel([string]$AtlasRef, [string]$ParticleRef) {
    $copycatAtlasRef = if ($AtlasRef -like "camowarfare:block/*/*_atlas") { $AtlasRef -replace "_atlas$", "" } else { $null }
    return [ordered]@{
        render_type = "minecraft:solid"
        parent = "minecraft:block/block"
        textures = [ordered]@{
            atlas = $AtlasRef
            particle = $ParticleRef
            copycat_atlas = $copycatAtlasRef
        }
        loader = "camowarfare:connected_camo"
    }
}

function New-ConnectedItemModel([string]$AtlasRef, [string]$ParticleRef) {
    $copycatAtlasRef = if ($AtlasRef -like "camowarfare:block/*/*_atlas") { $AtlasRef -replace "_atlas$", "" } else { $null }
    return [ordered]@{
        render_type = "minecraft:solid"
        parent = "minecraft:block/block"
        item_render = $true
        textures = [ordered]@{
            atlas = $AtlasRef
            particle = $ParticleRef
            copycat_atlas = $copycatAtlasRef
        }
        loader = "camowarfare:connected_camo"
    }
}

function New-AppearanceModel([string]$TextureRef) {
    return [ordered]@{
        render_type = "minecraft:solid"
        parent = "minecraft:block/cube_all"
        textures = [ordered]@{
            all = $TextureRef
            particle = $TextureRef
        }
    }
}

$convertedBlockModels = 0
$convertedItemModels = 0
$maskSources = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

Get-ChildItem -Path $blockModelsRoot -Filter *.json | Sort-Object Name | ForEach-Object {
    $modelPath = $_.FullName
    $modelName = $_.BaseName
    $json = Get-Content -Raw $modelPath | ConvertFrom-Json

    if ($modelName -like "*_appearance") {
        $sourceRef = $null
        if ($json.textures) {
            if ($json.textures.particle -is [string] -and -not [string]::IsNullOrWhiteSpace($json.textures.particle)) {
                $sourceRef = $json.textures.particle
            } elseif ($json.textures.atlas -is [string] -and -not [string]::IsNullOrWhiteSpace($json.textures.atlas)) {
                $sourceRef = $json.textures.atlas
            } elseif ($json.textures.all -is [string] -and -not [string]::IsNullOrWhiteSpace($json.textures.all)) {
                $sourceRef = $json.textures.all
            }
        }

        if ($sourceRef -like "camowarfare:block/*/*_atlas") {
            $sourcePath = Get-TextureFilePath $sourceRef
            if ($sourcePath -and (Test-Path $sourcePath)) {
                $appearanceRef = $sourceRef -replace "_atlas$", "_appearance_atlas"
                $appearancePath = Get-TextureFilePath $appearanceRef
                $sourceBitmap = [System.Drawing.Bitmap]::new($sourcePath)
                try {
                    Draw-TiledAppearanceTexture $sourceBitmap $appearancePath
                }
                finally {
                    $sourceBitmap.Dispose()
                }
                Save-JsonFile $modelPath (New-AppearanceModel $appearanceRef)
            }
        }
        return
    }

    $isPlainSampleCube = $json.parent -eq "minecraft:block/cube_all" -and
        $null -ne $json.textures -and
        $json.textures.all -is [string] -and
        $json.textures.all -like "camowarfare:block/*/*_atlas"

    if ($isPlainSampleCube) {
        $atlasRef = $json.textures.all
        $particleRef = if ([string]::IsNullOrWhiteSpace($json.textures.particle)) { $atlasRef } else { $json.textures.particle }
        Save-JsonFile $modelPath (New-ConnectedBlockModel $atlasRef $particleRef)
        $convertedBlockModels++
        $maskSources.Add($atlasRef) | Out-Null

        $itemModelPath = Join-Path $itemModelsRoot ($modelName + ".json")
        if (Test-Path $itemModelPath) {
            Save-JsonFile $itemModelPath (New-ConnectedItemModel $atlasRef $particleRef)
            $convertedItemModels++
        }
        return
    }

    $isConnectedSingleAtlas = $json.loader -eq "camowarfare:connected_camo" -and
        $modelName -ne "matte_olive_panel_block" -and
        $null -ne $json.textures -and
        $json.textures.atlas -is [string] -and
        [string]::IsNullOrWhiteSpace($json.textures.north) -and
        [string]::IsNullOrWhiteSpace($json.textures.south) -and
        [string]::IsNullOrWhiteSpace($json.textures.east) -and
        [string]::IsNullOrWhiteSpace($json.textures.west) -and
        [string]::IsNullOrWhiteSpace($json.textures.up) -and
        [string]::IsNullOrWhiteSpace($json.textures.down)

    if ($isConnectedSingleAtlas) {
        $maskSources.Add($json.textures.atlas) | Out-Null
    }
}

$generatedMaskSets = 0
foreach ($resourcePath in $maskSources) {
    if (Ensure-FillSafeMasks $resourcePath) {
        $generatedMaskSets++
    }
}

Write-Output ("Converted block models: " + $convertedBlockModels)
Write-Output ("Converted item models: " + $convertedItemModels)
Write-Output ("Generated fill-safe mask sets: " + $generatedMaskSets)
