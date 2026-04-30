$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $root "src\main\resources\assets\camowarfare"
$modelsDir = Join-Path $assetsRoot "models\block"
$texturesRoot = Join-Path $assetsRoot "textures"

function Get-TextureFilePath([string]$ResourcePath) {
    if (-not $ResourcePath.StartsWith("camowarfare:")) {
        return $null
    }
    $relative = $ResourcePath.Substring("camowarfare:".Length).Replace("/", "\") + ".png"
    return Join-Path $texturesRoot $relative
}

function Export-MaskTextures([string]$TexturePath) {
    if (-not (Test-Path $TexturePath)) {
        return
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($TexturePath)
    if ($baseName -match "_m\d+$") {
        return
    }

    $bitmap = [System.Drawing.Bitmap]::new($TexturePath)
    try {
        if (($bitmap.Width % 4) -ne 0 -or ($bitmap.Height % 4) -ne 0) {
            return
        }

        $tileWidth = [int]($bitmap.Width / 4)
        $tileHeight = [int]($bitmap.Height / 4)
        for ($mask = 0; $mask -lt 16; $mask++) {
            $col = $mask % 4
            $row = [int][Math]::Floor($mask / 4)
            $rect = [System.Drawing.Rectangle]::new($col * $tileWidth, $row * $tileHeight, $tileWidth, $tileHeight)
            $tile = $bitmap.Clone($rect, $bitmap.PixelFormat)
            try {
                $destination = Join-Path ([System.IO.Path]::GetDirectoryName($TexturePath)) ($baseName + "_m" + $mask + ".png")
                $tile.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
            }
            finally {
                $tile.Dispose()
            }
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

$texturePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

Get-ChildItem -Path $modelsDir -Filter *.json | ForEach-Object {
    $json = Get-Content -Raw $_.FullName | ConvertFrom-Json
    if ($json.loader -ne "camowarfare:connected_camo") {
        return
    }
    foreach ($property in @("atlas", "north", "south", "east", "west", "up", "down")) {
        $value = $json.textures.$property
        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }
        $textureFile = Get-TextureFilePath $value
        if ($textureFile) {
            $texturePaths.Add($textureFile) | Out-Null
        }
    }
}

foreach ($texturePath in $texturePaths) {
    Export-MaskTextures $texturePath
}

Write-Output ("Generated split mask textures for " + $texturePaths.Count + " connected camo atlases")
