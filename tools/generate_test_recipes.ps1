$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$javaPath = Join-Path $root 'src\main\java\com\camowarfare\CamoFamily.java'
$recipeDir = Join-Path $root 'src\main\resources\data\camowarfare\recipe'
$originalDir = Join-Path $recipeDir 'original'
$stonecuttingDir = Join-Path $recipeDir 'stonecutting'
$createMixingDir = Join-Path $recipeDir 'compat\create\mixing'
$createCuttingDir = Join-Path $recipeDir 'compat\create\cutting'

New-Item -ItemType Directory -Force -Path $recipeDir, $originalDir, $stonecuttingDir, $createMixingDir, $createCuttingDir | Out-Null
Get-ChildItem -Path $recipeDir -Recurse -Filter '*.json' -File -ErrorAction SilentlyContinue | Remove-Item -Force

function Write-Utf8Json {
    param(
        [string]$Path,
        [object]$Value
    )

    $json = $Value | ConvertTo-Json -Depth 20
    [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false))
}

function New-ItemIngredient {
    param([string]$Item)
    return [ordered]@{ item = $Item }
}

function New-TagIngredient {
    param([string]$Tag)
    return [ordered]@{ tag = $Tag }
}

function New-Result {
    param(
        [string]$Id,
        [int]$Count = 1
    )

    return [ordered]@{
        id = $Id
        count = $Count
    }
}

function New-CreateConditions {
    return ,([ordered]@{
        type = 'neoforge:mod_loaded'
        modid = 'create'
    })
}

function Write-ShapedCenterRecipe {
    param(
        [string]$Path,
        [object]$OuterIngredient,
        [object]$CenterIngredient,
        [string]$ResultId,
        [int]$Count
    )

    $payload = [ordered]@{
        type = 'minecraft:crafting_shaped'
        category = 'building'
        pattern = @(
            'XXX',
            'XYX',
            'XXX'
        )
        key = [ordered]@{
            X = $OuterIngredient
            Y = $CenterIngredient
        }
        result = New-Result -Id $ResultId -Count $Count
    }
    Write-Utf8Json -Path $Path -Value $payload
}

function Write-ShapelessPairRecipe {
    param(
        [string]$Path,
        [object[]]$Ingredients,
        [string]$ResultId,
        [int]$Count = 1
    )

    $payload = [ordered]@{
        type = 'minecraft:crafting_shapeless'
        category = 'building'
        ingredients = $Ingredients
        result = New-Result -Id $ResultId -Count $Count
    }
    Write-Utf8Json -Path $Path -Value $payload
}

function Write-StonecuttingRecipe {
    param(
        [string]$Path,
        [object]$Ingredient,
        [string]$ResultId,
        [int]$Count = 1
    )

    $payload = [ordered]@{
        type = 'minecraft:stonecutting'
        ingredient = $Ingredient
        result = New-Result -Id $ResultId -Count $Count
    }
    Write-Utf8Json -Path $Path -Value $payload
}

function Write-CreateMixingRecipe {
    param(
        [string]$Path,
        [object[]]$Ingredients,
        [string]$ResultId,
        [int]$Count = 1,
        [bool]$Heated = $false
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('{')
    $lines.Add('  "neoforge:conditions": [')
    $lines.Add('    {')
    $lines.Add('      "type": "neoforge:mod_loaded",')
    $lines.Add('      "modid": "create"')
    $lines.Add('    }')
    $lines.Add('  ],')
    $lines.Add('  "type": "create:mixing",')
    if ($Heated) {
        $lines.Add('  "heat_requirement": "heated",')
    }
    $lines.Add('  "ingredients": [')
    for ($i = 0; $i -lt $Ingredients.Count; $i++) {
        $ingredientJson = ($Ingredients[$i] | ConvertTo-Json -Depth 10) -split "`r?`n"
        for ($j = 0; $j -lt $ingredientJson.Length; $j++) {
            $prefix = '    '
            $suffix = ''
            if ($j -eq $ingredientJson.Length - 1 -and $i -lt $Ingredients.Count - 1) { $suffix = ',' }
            $lines.Add($prefix + $ingredientJson[$j] + $suffix)
        }
    }
    $lines.Add('  ],')
    $lines.Add('  "results": [')
    $resultJson = ((New-Result -Id $ResultId -Count $Count) | ConvertTo-Json -Depth 10) -split "`r?`n"
    for ($i = 0; $i -lt $resultJson.Length; $i++) {
        $lines.Add('    ' + $resultJson[$i])
    }
    $lines.Add('  ]')
    $lines.Add('}')
    [IO.File]::WriteAllText($Path, ($lines -join "`r`n"), [Text.UTF8Encoding]::new($false))
}

function Write-CreateCuttingRecipe {
    param(
        [string]$Path,
        [object]$Ingredient,
        [string]$ResultId,
        [int]$Count = 1
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('{')
    $lines.Add('  "neoforge:conditions": [')
    $lines.Add('    {')
    $lines.Add('      "type": "neoforge:mod_loaded",')
    $lines.Add('      "modid": "create"')
    $lines.Add('    }')
    $lines.Add('  ],')
    $lines.Add('  "type": "create:cutting",')
    $lines.Add('  "ingredients": [')
    $ingredientJson = ($Ingredient | ConvertTo-Json -Depth 10) -split "`r?`n"
    for ($i = 0; $i -lt $ingredientJson.Length; $i++) {
        $lines.Add('    ' + $ingredientJson[$i])
    }
    $lines.Add('  ],')
    $lines.Add('  "processing_time": 50,')
    $lines.Add('  "results": [')
    $resultJson = ((New-Result -Id $ResultId -Count $Count) | ConvertTo-Json -Depth 10) -split "`r?`n"
    for ($i = 0; $i -lt $resultJson.Length; $i++) {
        $lines.Add('    ' + $resultJson[$i])
    }
    $lines.Add('  ]')
    $lines.Add('}')
    [IO.File]::WriteAllText($Path, ($lines -join "`r`n"), [Text.UTF8Encoding]::new($false))
}

function Repeat-Ingredient {
    param(
        [object]$Ingredient,
        [int]$Count
    )

    $items = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $Count; $i++) {
        $items.Add($Ingredient)
    }
    return $items
}

function Get-OverlaySourceFamilyId {
    param([string]$FamilyId)

    foreach ($suffix in '_riveted', '_stained', '_weathered') {
        if ($FamilyId.EndsWith($suffix)) {
            return $FamilyId.Substring(0, $FamilyId.Length - $suffix.Length)
        }
    }
    return $null
}

function Get-OverlayIngredient {
    param([string]$FamilyId)

    if ($FamilyId.EndsWith('_riveted')) { return 'minecraft:iron_nugget' }
    if ($FamilyId.EndsWith('_stained')) { return 'minecraft:ink_sac' }
    if ($FamilyId.EndsWith('_weathered')) { return 'minecraft:flint' }
    throw "Unknown overlay family: $FamilyId"
}

function Get-SolidDye {
    param([string]$FamilyId)

    switch ($FamilyId) {
        'solid_military_green' { return 'minecraft:green_dye' }
        'solid_desert_sand' { return 'minecraft:yellow_dye' }
        'solid_bluegray' { return 'minecraft:light_blue_dye' }
        'solid_night_black' { return 'minecraft:black_dye' }
        default { throw "Unknown solid family: $FamilyId" }
    }
}

function Get-BaseSourceSolidFamilyId {
    param([string]$FamilyId)

    switch -Regex ($FamilyId) {
'^naval_bluegray(_camo|_digital|_splinter)?$|^ocean_blue_digital$|^coastal_blue_digital$' { return 'solid_bluegray' }
        '^pla_05_naval_blue(_hull)?$' { return 'solid_bluegray' }
        '^urban_digital(_hull)?$' { return 'solid_bluegray' }
        '^urban_gray_(camo|digital|splinter)$' { return 'solid_bluegray' }
        '^snow_graywhite_(camo|digital|splinter)$' { return 'solid_bluegray' }
        '^nato_desert$|^russian_desert$|^desert_digital$|^desert_modern$|^desert_brush$' { return 'solid_desert_sand' }
        '^black_night(_hull)?$|^night_lowvis_(camo|digital|splinter)$' { return 'solid_night_black' }
        default { return 'solid_military_green' }
    }
}

function Get-BaseAccent {
    param([string]$FamilyId)

    switch ($FamilyId) {
        'nato_woodland' { return 'minecraft:brown_dye' }
        'woodland_macro' { return 'minecraft:brown_dye' }
        'russian_green_splinter' { return 'minecraft:black_dye' }
        'russian_desert' { return 'minecraft:brown_dye' }
        'nato_desert' { return 'minecraft:orange_dye' }
        'desert_modern' { return 'minecraft:yellow_dye' }
        'desert_brush' { return 'minecraft:brown_dye' }
        'woodland_digital' { return 'minecraft:gray_dye' }
        'desert_digital' { return 'minecraft:gray_dye' }
        'urban_digital' { return 'minecraft:gray_dye' }
        'urban_digital_hull' { return 'minecraft:gray_dye' }
        'urban_gray_camo' { return 'minecraft:light_gray_dye' }
        'urban_gray_digital' { return 'minecraft:gray_dye' }
        'urban_gray_splinter' { return 'minecraft:gray_dye' }
'naval_bluegray' { return 'minecraft:cyan_dye' }
'naval_bluegray_camo' { return 'minecraft:light_blue_dye' }
'naval_bluegray_digital' { return 'minecraft:gray_dye' }
'naval_bluegray_splinter' { return 'minecraft:cyan_dye' }
'coastal_blue_digital' { return 'minecraft:light_blue_dye' }
'ocean_blue_digital' { return 'minecraft:blue_dye' }
        'winter_whitewash' { return 'minecraft:white_dye' }
        'winter_whitewash_hull' { return 'minecraft:white_dye' }
        'snow_graywhite_camo' { return 'minecraft:light_gray_dye' }
        'snow_graywhite_digital' { return 'minecraft:gray_dye' }
        'snow_graywhite_splinter' { return 'minecraft:light_gray_dye' }
        'black_night' { return 'minecraft:gray_dye' }
        'black_night_hull' { return 'minecraft:gray_dye' }
        'night_lowvis_camo' { return 'minecraft:gray_dye' }
        'night_lowvis_digital' { return 'minecraft:gray_dye' }
        'night_lowvis_splinter' { return 'minecraft:gray_dye' }
        'stryker_deep_olive' { return 'minecraft:black_dye' }
        'pla_05_naval_blue' { return 'minecraft:blue_dye' }
        'pla_05_naval_blue_hull' { return 'minecraft:blue_dye' }
        'ukrainian_yellow_green' { return 'minecraft:yellow_dye' }
        'pla_woodland' { return 'minecraft:lime_dye' }
        'pla_mountain' { return 'minecraft:light_gray_dye' }
        'pla_mountain_digital' { return 'minecraft:gray_dye' }
        'pla_mountain_tiger' { return 'minecraft:brown_dye' }
        default { throw "Unknown base family: $FamilyId" }
    }
}

$families = foreach ($line in Get-Content -Path $javaPath -Encoding UTF8) {
    if ($line -match '^\s*[A-Z0-9_]+\("([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*MapColor\.[A-Z_]+,\s*(null|"([^"]+)")\)[,;]?$') {
        [pscustomobject]@{
            Id = $matches[1]
            Zh = $matches[2]
            En = $matches[3]
            Legacy = $matches[5]
        }
    }
}

$variants = @('a', 'b', 'c', 'd')
$armorPlateId = 'camowarfare:armor_plate_block'
$armorPlateConcreteTag = 'camowarfare:armor_plate_concretes'

# Armor plate base recipes
Write-Utf8Json -Path (Join-Path $originalDir 'armor_plate_block.json') -Value ([ordered]@{
    type = 'minecraft:crafting_shaped'
    category = 'building'
    pattern = @(
        'XI',
        'IX'
    )
    key = [ordered]@{
        X = New-TagIngredient -Tag $armorPlateConcreteTag
        I = New-ItemIngredient -Item 'minecraft:iron_block'
    }
    result = New-Result -Id $armorPlateId -Count 4
})

$armorPlateMixingIngredients = New-Object System.Collections.Generic.List[object]
$armorPlateMixingIngredients.Add((New-TagIngredient -Tag $armorPlateConcreteTag))
$armorPlateMixingIngredients.Add((New-TagIngredient -Tag $armorPlateConcreteTag))
$armorPlateMixingIngredients.Add((New-ItemIngredient -Item 'minecraft:iron_block'))
$armorPlateMixingIngredients.Add((New-ItemIngredient -Item 'minecraft:iron_block'))
Write-CreateMixingRecipe -Path (Join-Path $createMixingDir 'armor_plate_block.json') -Ingredients $armorPlateMixingIngredients -ResultId $armorPlateId -Count 4 -Heated $true

foreach ($family in $families) {
    $overlaySource = Get-OverlaySourceFamilyId -FamilyId $family.Id
    $isOverlay = $null -ne $overlaySource
    $isSolid = $family.Id.StartsWith('solid_')

    if ($isSolid) {
        $dye = Get-SolidDye -FamilyId $family.Id
        Write-ShapedCenterRecipe `
            -Path (Join-Path $originalDir "$($family.Id)_a_block.json") `
            -OuterIngredient (New-ItemIngredient -Item $armorPlateId) `
            -CenterIngredient (New-ItemIngredient -Item $dye) `
            -ResultId "camowarfare:$($family.Id)_a_block" `
            -Count 8

        $ingredients = New-Object System.Collections.Generic.List[object]
        foreach ($ingredient in (Repeat-Ingredient -Ingredient (New-ItemIngredient -Item $armorPlateId) -Count 8)) {
            $ingredients.Add($ingredient)
        }
        $ingredients.Add((New-ItemIngredient -Item $dye))
        Write-CreateMixingRecipe `
            -Path (Join-Path $createMixingDir "$($family.Id)_a_block.json") `
            -Ingredients $ingredients `
            -ResultId "camowarfare:$($family.Id)_a_block" `
            -Count 8
    } elseif (-not $isOverlay) {
        $solidFamilyId = Get-BaseSourceSolidFamilyId -FamilyId $family.Id
        $accent = Get-BaseAccent -FamilyId $family.Id
        $sourceSolidA = "camowarfare:${solidFamilyId}_a_block"

        Write-ShapedCenterRecipe `
            -Path (Join-Path $originalDir "$($family.Id)_a_block.json") `
            -OuterIngredient (New-ItemIngredient -Item $sourceSolidA) `
            -CenterIngredient (New-ItemIngredient -Item $accent) `
            -ResultId "camowarfare:$($family.Id)_a_block" `
            -Count 8

        $ingredients = New-Object System.Collections.Generic.List[object]
        foreach ($ingredient in (Repeat-Ingredient -Ingredient (New-ItemIngredient -Item $sourceSolidA) -Count 8)) {
            $ingredients.Add($ingredient)
        }
        $ingredients.Add((New-ItemIngredient -Item $accent))
        Write-CreateMixingRecipe `
            -Path (Join-Path $createMixingDir "$($family.Id)_a_block.json") `
            -Ingredients $ingredients `
            -ResultId "camowarfare:$($family.Id)_a_block" `
            -Count 8
    }

    if ($isOverlay) {
        $ingredient = Get-OverlayIngredient -FamilyId $family.Id
        foreach ($variant in $variants) {
            $source = "camowarfare:${overlaySource}_${variant}_block"
            $result = "camowarfare:$($family.Id)_${variant}_block"
            Write-ShapelessPairRecipe `
                -Path (Join-Path $originalDir "$($family.Id)_${variant}_block.json") `
                -Ingredients @(
                    (New-ItemIngredient -Item $source),
                    (New-ItemIngredient -Item $ingredient)
                ) `
                -ResultId $result

            Write-CreateMixingRecipe `
                -Path (Join-Path $createMixingDir "$($family.Id)_${variant}_block.json") `
                -Ingredients @(
                    (New-ItemIngredient -Item $source),
                    (New-ItemIngredient -Item $ingredient)
                ) `
                -ResultId $result
        }
    }

    foreach ($from in $variants) {
        foreach ($to in $variants) {
            if ($from -eq $to) { continue }
            $source = "camowarfare:$($family.Id)_${from}_block"
            $result = "camowarfare:$($family.Id)_${to}_block"

            Write-StonecuttingRecipe `
                -Path (Join-Path $stonecuttingDir "$($family.Id)_${to}_from_${from}.json") `
                -Ingredient (New-ItemIngredient -Item $source) `
                -ResultId $result

            Write-CreateCuttingRecipe `
                -Path (Join-Path $createCuttingDir "$($family.Id)_${to}_from_${from}.json") `
                -Ingredient (New-ItemIngredient -Item $source) `
                -ResultId $result
        }
    }
}
