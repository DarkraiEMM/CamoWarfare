$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $root "src\main\resources\assets\camowarfare"
$modelsDir = Join-Path $assetsRoot "models\block"
$texturesRoot = Join-Path $assetsRoot "textures"

function Resolve-TexturePath([string]$resourcePath) {
    if ([string]::IsNullOrWhiteSpace($resourcePath)) {
        return $null
    }
    if (-not $resourcePath.StartsWith("camowarfare:")) {
        return $null
    }
    $relative = $resourcePath.Substring("camowarfare:".Length).Replace("/", "\") + ".png"
    return Join-Path $texturesRoot $relative
}

$models = Get-ChildItem $modelsDir -Filter *.json | ForEach-Object {
    $json = Get-Content -Raw $_.FullName | ConvertFrom-Json
    [pscustomobject]@{
        Name = $_.Name
        Loader = [string]$json.loader
        Parent = [string]$json.parent
        Textures = $json.textures
    }
}

$connectedModels = @($models | Where-Object { $_.Loader -eq "camowarfare:connected_camo" })
$standardCubeModels = @($models | Where-Object { $_.Parent -eq "minecraft:block/cube_all" -or $_.Parent -eq "block/cube_all" })
$customBlockModels = @($models | Where-Object { $_.Parent -eq "block/block" -or $_.Parent -eq "minecraft:block/block" })
$plainSampleCubeModels = @($models | Where-Object {
    ($_.Parent -eq "minecraft:block/cube_all" -or $_.Parent -eq "block/cube_all") -and
    $_.Textures -and
    $_.Textures.all -is [string] -and
    $_.Textures.all -like "camowarfare:block/*/*_atlas"
})

$missingSplitTextures = New-Object System.Collections.Generic.List[object]
foreach ($model in $connectedModels) {
    $textureRefs = @(
        $model.Textures.atlas,
        $model.Textures.north,
        $model.Textures.south,
        $model.Textures.east,
        $model.Textures.west,
        $model.Textures.up,
        $model.Textures.down
    ) | Where-Object { $_ } | Select-Object -Unique

    foreach ($textureRef in $textureRefs) {
        $texturePath = Resolve-TexturePath $textureRef
        if (-not $texturePath -or -not (Test-Path $texturePath)) {
            $missingSplitTextures.Add([pscustomobject]@{
                Model = $model.Name
                Texture = $textureRef
                Missing = "base"
            }) | Out-Null
            continue
        }

        $missingMasks = @()
        for ($i = 0; $i -lt 16; $i++) {
            if (-not (Test-Path ($texturePath.Replace(".png", "_m" + $i + ".png")))) {
                $missingMasks += $i
            }
        }

        if ($missingMasks.Count -gt 0) {
            $missingSplitTextures.Add([pscustomobject]@{
                Model = $model.Name
                Texture = $textureRef
                Missing = ($missingMasks -join ",")
            }) | Out-Null
        }
    }
}

$perFaceConnected = @($connectedModels | Where-Object {
    $_.Textures.north -or $_.Textures.south -or $_.Textures.east -or $_.Textures.west -or $_.Textures.up -or $_.Textures.down
})

Write-Output "Copycat Fill Compatibility Audit"
Write-Output ("Workspace: " + $root)
Write-Output ("Total block models: " + $models.Count)
Write-Output ("Standard cube models: " + $standardCubeModels.Count)
Write-Output ("Plain sample cube models: " + $plainSampleCubeModels.Count)
Write-Output ("Connected camo models: " + $connectedModels.Count)
Write-Output ("Custom block/block models: " + $customBlockModels.Count)
Write-Output ("Per-face connected models: " + $perFaceConnected.Count)

if ($missingSplitTextures.Count -eq 0) {
    Write-Output "Connected camo split textures: OK"
} else {
    Write-Output "Connected camo split textures: MISSING"
    $missingSplitTextures | Format-Table -AutoSize
}

if ($perFaceConnected.Count -gt 0) {
    Write-Output ""
    Write-Output "Per-face connected models:"
    $perFaceConnected | Select-Object Name | Format-Table -AutoSize
}
