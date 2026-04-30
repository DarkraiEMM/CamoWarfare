$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$assetsRoot = Join-Path $root "src\main\resources\assets\camowarfare"
$dataRoot = Join-Path $root "src\main\resources\data"
$itemModelRoot = Join-Path $assetsRoot "models\item"
$itemTextureRoot = Join-Path $assetsRoot "textures\item"
$recipeRoot = Join-Path $dataRoot "camowarfare\recipe"
$originalRecipeRoot = Join-Path $recipeRoot "original"
$stonecuttingRoot = Join-Path $recipeRoot "stonecutting"
$enLangPath = Join-Path $assetsRoot "lang\en_us.json"
$zhLangPath = Join-Path $assetsRoot "lang\zh_cn.json"

function Ensure-Dir([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Save-Json([string]$Path, $Data) {
    Ensure-Dir (Split-Path -Parent $Path)
    $json = $Data | ConvertTo-Json -Depth 24
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Load-Json([string]$Path) {
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Color([string]$Hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function Draw-StencilTexture([string]$Id, [string]$AccentHex, [string]$Mode) {
    Ensure-Dir $itemTextureRoot
    $path = Join-Path $itemTextureRoot ("spray_stencil_" + $Id + ".png")
    $bmp = [System.Drawing.Bitmap]::new(32, 32, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    try {
        $g.Clear([System.Drawing.Color]::Transparent)
        $plate = [System.Drawing.SolidBrush]::new((Color "#6B7177"))
        $edge = [System.Drawing.Pen]::new((Color "#D1D6DA"), 2)
        $dark = [System.Drawing.SolidBrush]::new((Color "#20252A"))
        $accent = [System.Drawing.SolidBrush]::new((Color $AccentHex))
        try {
            $g.FillRectangle($plate, 5, 3, 22, 26)
            $g.DrawRectangle($edge, 5, 3, 22, 26)
            $g.FillRectangle($dark, 8, 6, 16, 20)
            switch ($Mode) {
                "blotch" {
                    $g.FillRectangle($accent, 10, 8, 7, 5)
                    $g.FillRectangle($accent, 16, 12, 6, 6)
                    $g.FillRectangle($accent, 11, 19, 9, 4)
                }
                "splinter" {
                    $g.FillPolygon($accent, @([System.Drawing.Point]::new(9,9), [System.Drawing.Point]::new(23,11), [System.Drawing.Point]::new(15,16)))
                    $g.FillPolygon($accent, @([System.Drawing.Point]::new(10,20), [System.Drawing.Point]::new(24,17), [System.Drawing.Point]::new(21,24)))
                }
                "digital" {
                    foreach ($r in @(@(9,8,4,4), @(14,8,5,3), @(20,12,3,5), @(11,17,6,3), @(17,21,5,3))) {
                        $g.FillRectangle($accent, $r[0], $r[1], $r[2], $r[3])
                    }
                }
                "stripe" {
                    $g.FillRectangle($accent, 9, 8, 14, 3)
                    $g.FillRectangle($accent, 8, 15, 15, 3)
                    $g.FillRectangle($accent, 10, 22, 12, 3)
                }
                "tiger" {
                    $g.FillPolygon($accent, @([System.Drawing.Point]::new(8,9), [System.Drawing.Point]::new(23,11), [System.Drawing.Point]::new(11,14)))
                    $g.FillPolygon($accent, @([System.Drawing.Point]::new(9,17), [System.Drawing.Point]::new(24,16), [System.Drawing.Point]::new(12,21)))
                    $g.FillPolygon($accent, @([System.Drawing.Point]::new(10,23), [System.Drawing.Point]::new(22,22), [System.Drawing.Point]::new(14,26)))
                }
                "multiterrain" {
                    $g.FillRectangle($accent, 9, 8, 5, 5)
                    $g.FillPolygon($accent, @([System.Drawing.Point]::new(16,10), [System.Drawing.Point]::new(24,13), [System.Drawing.Point]::new(18,18)))
                    $g.FillRectangle($accent, 11, 20, 9, 4)
                }
                "whitewash" {
                    $g.FillRectangle($accent, 9, 8, 14, 4)
                    $g.FillRectangle($accent, 10, 15, 10, 3)
                    $g.FillRectangle($accent, 12, 22, 11, 3)
                }
                "lowvis" {
                    $g.FillRectangle($accent, 10, 9, 12, 3)
                    $g.FillRectangle($accent, 13, 14, 7, 3)
                    $g.FillRectangle($accent, 9, 20, 13, 3)
                }
            }
        }
        finally {
            $plate.Dispose()
            $edge.Dispose()
            $dark.Dispose()
            $accent.Dispose()
        }
        $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $g.Dispose()
        $bmp.Dispose()
    }
}

function IngredientItem([string]$Item) {
    return [ordered]@{ item = $Item }
}

function IngredientTag([string]$Tag) {
    return [ordered]@{ tag = $Tag }
}

function Result([string]$Id, [int]$Count = 1) {
    return [ordered]@{ id = $Id; count = $Count }
}

function Save-ShapelessRecipe([string]$Name, [object[]]$Ingredients, [string]$ResultId, [int]$Count = 1) {
    Save-Json (Join-Path $originalRecipeRoot ($Name + ".json")) ([ordered]@{
        type = "minecraft:crafting_shapeless"
        category = "building"
        ingredients = $Ingredients
        result = (Result $ResultId $Count)
    })
}

function Save-CreateMixingRecipe([string]$Name, [object[]]$Ingredients, [string]$ResultId, [int]$Count = 1, [bool]$Heated = $false) {
    $data = [ordered]@{
        "neoforge:conditions" = @(
            [ordered]@{
                type = "neoforge:mod_loaded"
                modid = "create"
            }
        )
        type = "create:mixing"
        ingredients = $Ingredients
        results = @((Result $ResultId $Count))
    }
    if ($Heated) {
        $data.heat_requirement = "heated"
    }
    Save-Json (Join-Path $recipeRoot ("compat\create\mixing\" + $Name + ".json")) $data
}

function Save-CreateCuttingRecipe([string]$Name, [string]$IngredientId, [string]$ResultId, [int]$Count = 1) {
    Save-Json (Join-Path $recipeRoot ("compat\create\cutting\" + $Name + ".json")) ([ordered]@{
        "neoforge:conditions" = @(
            [ordered]@{
                type = "neoforge:mod_loaded"
                modid = "create"
            }
        )
        type = "create:cutting"
        ingredients = @((IngredientItem $IngredientId))
        processing_time = 50
        results = @((Result $ResultId $Count))
    })
}

function Save-StonecutPair([string]$A, [string]$B) {
    Save-Json (Join-Path $stonecuttingRoot (($A -replace "camowarfare:", "") + "_to_" + ($B -replace "camowarfare:", "") + ".json")) ([ordered]@{
        type = "minecraft:stonecutting"
        ingredient = (IngredientItem $A)
        result = (Result $B 1)
    })
    Save-Json (Join-Path $stonecuttingRoot (($B -replace "camowarfare:", "") + "_to_" + ($A -replace "camowarfare:", "") + ".json")) ([ordered]@{
        type = "minecraft:stonecutting"
        ingredient = (IngredientItem $B)
        result = (Result $A 1)
    })
    Save-CreateCuttingRecipe (($A -replace "camowarfare:", "") + "_to_" + ($B -replace "camowarfare:", "")) $A $B 1
    Save-CreateCuttingRecipe (($B -replace "camowarfare:", "") + "_to_" + ($A -replace "camowarfare:", "")) $B $A 1
}

$stencils = @(
    @{ Id = "blotch"; En = "Blotch Spray Stencil"; Zh = "\u6591\u9a73\u55b7\u6d82\u677f"; Accent = "#8A6A42"; Mode = "blotch"; Dye = "minecraft:brown_dye"; Material = "minecraft:clay_ball" },
    @{ Id = "splinter"; En = "Splinter Spray Stencil"; Zh = "\u88c2\u6591\u55b7\u6d82\u677f"; Accent = "#6F8151"; Mode = "splinter"; Dye = "minecraft:green_dye"; Material = "minecraft:flint" },
    @{ Id = "digital"; En = "Digital Spray Stencil"; Zh = "\u6570\u7801\u55b7\u6d82\u677f"; Accent = "#7E8A8E"; Mode = "digital"; Dye = "minecraft:redstone"; Material = "minecraft:redstone" },
    @{ Id = "stripe"; En = "Stripe Spray Stencil"; Zh = "\u6761\u6591\u55b7\u6d82\u677f"; Accent = "#C09B6C"; Mode = "stripe"; Dye = "minecraft:yellow_dye"; Material = "minecraft:brick" },
    @{ Id = "tiger"; En = "Tiger Stripe Spray Stencil"; Zh = "\u864e\u6591\u55b7\u6d82\u677f"; Accent = "#2A3024"; Mode = "tiger"; Dye = "minecraft:black_dye"; Material = "minecraft:gunpowder" },
    @{ Id = "multiterrain"; En = "Multi-Terrain Spray Stencil"; Zh = "\u591a\u5730\u5f62\u55b7\u6d82\u677f"; Accent = "#9A8C62"; Mode = "multiterrain"; Dye = "minecraft:lime_dye"; Material = "minecraft:clay_ball" },
    @{ Id = "whitewash"; En = "Whitewash Spray Stencil"; Zh = "\u767d\u6d17\u55b7\u6d82\u677f"; Accent = "#F2F4F3"; Mode = "whitewash"; Dye = "minecraft:white_dye"; Material = "minecraft:bone_meal" },
    @{ Id = "lowvis"; En = "Low-Visibility Spray Stencil"; Zh = "\u4f4e\u53ef\u89c6\u55b7\u6d82\u677f"; Accent = "#3B444D"; Mode = "lowvis"; Dye = "minecraft:black_dye"; Material = "minecraft:gunpowder" }
)

foreach ($stencil in $stencils) {
    $itemId = "spray_stencil_" + $stencil.Id
    Draw-StencilTexture $stencil.Id $stencil.Accent $stencil.Mode
    Save-Json (Join-Path $itemModelRoot ($itemId + ".json")) ([ordered]@{
        parent = "minecraft:item/generated"
        textures = [ordered]@{
            layer0 = "camowarfare:item/$itemId"
        }
    })
    Save-ShapelessRecipe $itemId @(
        (IngredientItem "minecraft:paper"),
        (IngredientItem "minecraft:iron_nugget"),
        (IngredientItem "minecraft:iron_nugget"),
        (IngredientItem $stencil.Material),
        (IngredientItem $stencil.Dye)
    ) "camowarfare:$itemId" 1
    Save-CreateMixingRecipe $itemId @(
        (IngredientItem "minecraft:paper"),
        (IngredientItem "minecraft:iron_nugget"),
        (IngredientItem "minecraft:iron_nugget"),
        (IngredientItem $stencil.Material),
        (IngredientItem $stencil.Dye)
    ) "camowarfare:$itemId" 1 $false
}

$solidRecipes = @(
    @{ Id = "solid_military_green_standard_block"; Dyes = @("minecraft:lime_dye", "minecraft:yellow_dye") },
    @{ Id = "us_carc_green383_standard_block"; Dyes = @("minecraft:green_dye", "minecraft:yellow_dye", "minecraft:black_dye") },
    @{ Id = "us_carc_desert_tan_standard_block"; Dyes = @("minecraft:yellow_dye", "minecraft:brown_dye", "minecraft:white_dye") },
    @{ Id = "us_carc_blackgray_standard_block"; Dyes = @("minecraft:black_dye", "minecraft:gray_dye") },
    @{ Id = "solid_night_black_standard_block"; Dyes = @("minecraft:black_dye") },
    @{ Id = "solid_bluegray_standard_block"; Dyes = @("minecraft:blue_dye", "minecraft:gray_dye") },
    @{ Id = "urban_gray_splinter_standard_block"; Dyes = @("minecraft:gray_dye", "minecraft:light_gray_dye") }
)

foreach ($recipe in $solidRecipes) {
    $ingredients = New-Object System.Collections.Generic.List[object]
    $ingredients.Add((IngredientItem "camowarfare:armor_plate_block"))
    foreach ($dye in $recipe.Dyes) {
        $ingredients.Add((IngredientItem $dye))
    }
    Save-ShapelessRecipe $recipe.Id $ingredients.ToArray() "camowarfare:$($recipe.Id)" 1
    Save-CreateMixingRecipe $recipe.Id $ingredients.ToArray() "camowarfare:$($recipe.Id)" 1 $false
}

$stencilMaterials = @{}
foreach ($stencil in $stencils) {
    $stencilMaterials[$stencil.Id] = $stencil.Material
}

$camoRecipes = @(
    @{ Id = "woodland_blotch"; Base = "solid_military_green_standard_block"; Stencil = "blotch"; Dyes = @("minecraft:green_dye", "minecraft:brown_dye") },
    @{ Id = "russian_green_splinter"; Base = "solid_military_green_standard_block"; Stencil = "splinter"; Dyes = @("minecraft:green_dye", "minecraft:black_dye") },
    @{ Id = "ukrainian_yellow_green"; Base = "solid_military_green_standard_block"; Stencil = "blotch"; Dyes = @("minecraft:lime_dye", "minecraft:yellow_dye") },
    @{ Id = "afrika_korps"; Base = "us_carc_desert_tan_standard_block"; Stencil = "tiger"; Dyes = @("minecraft:brown_dye", "minecraft:black_dye") },
    @{ Id = "russian_desert"; Base = "us_carc_desert_tan_standard_block"; Stencil = "splinter"; Dyes = @("minecraft:brown_dye", "minecraft:yellow_dye") },
    @{ Id = "desert_brush"; Base = "us_carc_desert_tan_standard_block"; Stencil = "stripe"; Dyes = @("minecraft:brown_dye", "minecraft:orange_dye") },
    @{ Id = "winter_whitewash"; Base = "solid_bluegray_standard_block"; Stencil = "whitewash"; Dyes = @("minecraft:white_dye", "minecraft:light_gray_dye") },
    @{ Id = "snow_graywhite_digital"; Base = "solid_bluegray_standard_block"; Stencil = "digital"; Dyes = @("minecraft:white_dye", "minecraft:light_gray_dye") },
    @{ Id = "night_lowvis_digital"; Base = "solid_night_black_standard_block"; Stencil = "digital"; Dyes = @("minecraft:black_dye", "minecraft:gray_dye") },
    @{ Id = "coastal_blue_digital"; Base = "solid_bluegray_standard_block"; Stencil = "digital"; Dyes = @("minecraft:lapis_lazuli", "minecraft:light_blue_dye") },
    @{ Id = "ocean_blue_digital"; Base = "solid_bluegray_standard_block"; Stencil = "digital"; Dyes = @("minecraft:lapis_lazuli", "minecraft:cyan_dye") },
    @{ Id = "urban_digital"; Base = "urban_gray_splinter_standard_block"; Stencil = "digital"; Dyes = @("minecraft:gray_dye", "minecraft:black_dye") },
    @{ Id = "definition_sample_64"; Base = "solid_military_green_standard_block"; Stencil = "digital"; Dyes = @("minecraft:green_dye", "minecraft:brown_dye") },
    @{ Id = "nato_tricolor_mountain"; Base = "solid_military_green_standard_block"; Stencil = "blotch"; Dyes = @("minecraft:brown_dye", "minecraft:black_dye") },
    @{ Id = "turkish_multiterrain"; Base = "solid_military_green_standard_block"; Stencil = "multiterrain"; Dyes = @("minecraft:lime_dye", "minecraft:brown_dye") },
    @{ Id = "edrl_green"; Base = "solid_military_green_standard_block"; Stencil = "blotch"; Dyes = @("minecraft:green_dye", "minecraft:black_dye") },
    @{ Id = "russian_emr"; Base = "solid_military_green_standard_block"; Stencil = "digital"; Dyes = @("minecraft:green_dye", "minecraft:black_dye") },
    @{ Id = "us_ocp_multicam"; Base = "us_carc_green383_standard_block"; Stencil = "multiterrain"; Dyes = @("minecraft:brown_dye", "minecraft:lime_dye") }
)

$terrainBases = @(
    @{ Prefix = "pla"; Base = "solid_military_green_standard_block"; Stencil = "digital" },
    @{ Prefix = "nato"; Base = "solid_military_green_standard_block"; Stencil = "blotch" },
    @{ Prefix = "turkish"; Base = "solid_military_green_standard_block"; Stencil = "multiterrain" },
    @{ Prefix = "edrl"; Base = "solid_military_green_standard_block"; Stencil = "blotch" },
    @{ Prefix = "emr"; Base = "solid_military_green_standard_block"; Stencil = "digital" },
    @{ Prefix = "ocp"; Base = "us_carc_green383_standard_block"; Stencil = "multiterrain" }
)
$terrainDyes = @{
    woodland = @("minecraft:green_dye", "minecraft:brown_dye")
    mountain = @("minecraft:gray_dye", "minecraft:green_dye")
    desert = @("minecraft:yellow_dye", "minecraft:brown_dye")
    snow = @("minecraft:white_dye", "minecraft:light_gray_dye")
    urban = @("minecraft:gray_dye", "minecraft:black_dye")
}
foreach ($base in $terrainBases) {
    foreach ($terrain in @("woodland", "mountain", "desert", "snow", "urban")) {
        $camoRecipes += @{
            Id = "$($base.Prefix)_$terrain"
            Base = if ($terrain -eq "desert") { "us_carc_desert_tan_standard_block" } elseif ($terrain -eq "snow" -or $terrain -eq "urban") { "urban_gray_splinter_standard_block" } else { $base.Base }
            Stencil = $base.Stencil
            Dyes = $terrainDyes[$terrain]
        }
    }
}

foreach ($recipe in $camoRecipes) {
    $ingredients = New-Object System.Collections.Generic.List[object]
    $ingredients.Add((IngredientItem ("camowarfare:" + $recipe.Base)))
    $ingredients.Add((IngredientItem ("camowarfare:spray_stencil_" + $recipe.Stencil)))
    $ingredients.Add((IngredientItem $stencilMaterials[$recipe.Stencil]))
    foreach ($dye in $recipe.Dyes) {
        $ingredients.Add((IngredientItem $dye))
    }
    Save-ShapelessRecipe ($recipe.Id + "_standard_block") $ingredients.ToArray() ("camowarfare:" + $recipe.Id + "_standard_block") 1
    Save-CreateMixingRecipe ($recipe.Id + "_standard_block") $ingredients.ToArray() ("camowarfare:" + $recipe.Id + "_standard_block") 1 $false
}

$pairedIds = @()
$pairedIds += @($camoRecipes | ForEach-Object { $_.Id })
$pairedIds += @("definition_sample")
foreach ($id in ($pairedIds | Select-Object -Unique)) {
    $standard = if ($id -eq "definition_sample") { "camowarfare:definition_sample_64_block" } else { "camowarfare:${id}_standard_block" }
    $large = if ($id -eq "definition_sample") { "camowarfare:definition_sample_block" } else { "camowarfare:${id}_large_block" }
    Save-StonecutPair $standard $large
}

$en = Load-Json $enLangPath
$en | Add-Member -NotePropertyName "itemGroup.camowarfare.camouflage_warfare" -NotePropertyValue "Camouflage Warfare" -Force
foreach ($stencil in $stencils) {
    $key = "item.camowarfare.spray_stencil_" + $stencil.Id
    $en | Add-Member -NotePropertyName $key -NotePropertyValue $stencil.En -Force
}
Save-Json $enLangPath $en

Write-Output ("Spray stencils: " + $stencils.Count)
Write-Output ("Solid recipes: " + $solidRecipes.Count)
Write-Output ("Camo standard recipes: " + $camoRecipes.Count)
Write-Output ("Stonecutting pairs: " + ($pairedIds | Select-Object -Unique).Count)
