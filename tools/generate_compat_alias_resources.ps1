$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$javaPath = Join-Path $root "src\main\java\com\camowarfare\CamoFamily.java"
$resourcesRoot = Join-Path $root "src\main\resources"
$assetsRoot = Join-Path $resourcesRoot "assets\camowarfare"
$dataRoot = Join-Path $resourcesRoot "data"

$blockstateRoot = Join-Path $assetsRoot "blockstates"
$blockModelRoot = Join-Path $assetsRoot "models\block"
$itemModelRoot = Join-Path $assetsRoot "models\item"
$lootRoot = Join-Path $dataRoot "camowarfare\loot_tables\blocks"
$pickaxeTagPath = Join-Path $dataRoot "minecraft\tags\block\mineable\pickaxe.json"
$armoredTagPath = Join-Path $dataRoot "camowarfare\tags\block\armored_camouflage_blocks.json"

$compatAliases = @(
    @{ Id = "nato_desert_stained_a_block"; Family = "nato_desert"; Variant = "a" },
    @{ Id = "nato_desert_stained_b_block"; Family = "nato_desert"; Variant = "b" },
    @{ Id = "nato_desert_stained_c_block"; Family = "nato_desert"; Variant = "c" },
    @{ Id = "nato_desert_stained_d_block"; Family = "nato_desert"; Variant = "d" },
    @{ Id = "pla_05_naval_blue_stained_a_block"; Family = "pla_05_naval_blue"; Variant = "a" },
    @{ Id = "pla_05_naval_blue_stained_b_block"; Family = "pla_05_naval_blue"; Variant = "b" },
    @{ Id = "pla_05_naval_blue_stained_c_block"; Family = "pla_05_naval_blue"; Variant = "c" },
    @{ Id = "pla_05_naval_blue_stained_d_block"; Family = "pla_05_naval_blue"; Variant = "d" },
    @{ Id = "pla_05_naval_blue_weathered_a_block"; Family = "pla_05_naval_blue"; Variant = "a" },
    @{ Id = "pla_05_naval_blue_weathered_b_block"; Family = "pla_05_naval_blue"; Variant = "b" },
    @{ Id = "pla_05_naval_blue_weathered_c_block"; Family = "pla_05_naval_blue"; Variant = "c" },
    @{ Id = "pla_05_naval_blue_weathered_d_block"; Family = "pla_05_naval_blue"; Variant = "d" },
    @{ Id = "riveted_armor_green_a_block"; Family = "stryker_deep_olive_riveted"; Variant = "a" },
    @{ Id = "riveted_armor_green_b_block"; Family = "stryker_deep_olive_riveted"; Variant = "b" },
    @{ Id = "riveted_armor_green_c_block"; Family = "stryker_deep_olive_riveted"; Variant = "c" },
    @{ Id = "riveted_desert_sand_a_block"; Family = "nato_desert_riveted"; Variant = "a" },
    @{ Id = "riveted_desert_sand_b_block"; Family = "nato_desert_riveted"; Variant = "b" },
    @{ Id = "riveted_desert_sand_c_block"; Family = "nato_desert_riveted"; Variant = "c" },
    @{ Id = "stained_armor_green_a_block"; Family = "stryker_deep_olive_stained"; Variant = "a" },
    @{ Id = "stained_armor_green_b_block"; Family = "stryker_deep_olive_stained"; Variant = "b" },
    @{ Id = "stained_armor_green_c_block"; Family = "stryker_deep_olive_stained"; Variant = "c" },
    @{ Id = "stained_steel_bluegray_a_block"; Family = "naval_bluegray_camo"; Variant = "a" },
    @{ Id = "stained_steel_bluegray_b_block"; Family = "naval_bluegray_camo"; Variant = "b" },
    @{ Id = "stained_steel_bluegray_c_block"; Family = "naval_bluegray_camo"; Variant = "c" },
    @{ Id = "weathered_armor_green_a_block"; Family = "stryker_deep_olive_weathered"; Variant = "a" },
    @{ Id = "weathered_armor_green_b_block"; Family = "stryker_deep_olive_weathered"; Variant = "b" },
    @{ Id = "weathered_armor_green_c_block"; Family = "stryker_deep_olive_weathered"; Variant = "c" },
    @{ Id = "weathered_desert_sand_a_block"; Family = "nato_desert_weathered"; Variant = "a" },
    @{ Id = "weathered_desert_sand_b_block"; Family = "nato_desert_weathered"; Variant = "b" },
    @{ Id = "weathered_desert_sand_c_block"; Family = "nato_desert_weathered"; Variant = "c" }
)

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Save-Json([string]$Path, $Data) {
    Ensure-Dir (Split-Path -Parent $Path)
    $json = $Data | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
}

function Parse-Families() {
    $source = Get-Content -Raw -Path $javaPath
    $matches = [regex]::Matches($source, '^\s*[A-Z0-9_]+\("([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*MapColor\.[A-Z_]+,\s*(null|"([^"]+)")\)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $families = @{}
    foreach ($m in $matches) {
        $families[$m.Groups[1].Value] = @{
            Id = $m.Groups[1].Value
            Legacy = if ($m.Groups[5].Success -and $m.Groups[5].Value -ne "") { $m.Groups[5].Value } else { $null }
        }
    }
    return $families
}

function Write-AliasResources([string]$BlockId, [string]$FamilyId, [string]$Variant) {
    $textureRef = "camowarfare:block/$FamilyId/${Variant}_atlas"

    Save-Json (Join-Path $blockstateRoot ($BlockId + ".json")) @{
        multipart = @(
            @{
                apply = @{
                    model = "camowarfare:block/$BlockId"
                }
            }
        )
    }

    Save-Json (Join-Path $blockModelRoot ($BlockId + ".json")) @{
        parent = "minecraft:block/cube_all"
        render_type = "minecraft:solid"
        textures = @{
            all = $textureRef
            particle = $textureRef
        }
    }

    Save-Json (Join-Path $itemModelRoot ($BlockId + ".json")) @{
        parent = "camowarfare:block/$BlockId"
    }

    Save-Json (Join-Path $lootRoot ($BlockId + ".json")) @{
        type = "minecraft:block"
        pools = @(
            @{
                rolls = 1
                entries = @(
                    @{
                        type = "minecraft:item"
                        name = "camowarfare:$BlockId"
                    }
                )
                conditions = @(
                    @{
                        condition = "minecraft:survives_explosion"
                    }
                )
            }
        )
    }
}

$families = Parse-Families

foreach ($family in $families.Values) {
    if ($family.Legacy) {
        Write-AliasResources $family.Legacy $family.Id "a"
    }
}

foreach ($alias in $compatAliases) {
    Write-AliasResources $alias.Id $alias.Family $alias.Variant
}

$pickaxeValues = [System.Collections.Generic.List[string]]::new()
$pickaxeValues.Add("#camowarfare:attachment_blocks")
$pickaxeValues.Add("camowarfare:armor_plate_block")

$armoredValues = [System.Collections.Generic.List[string]]::new()
$armoredValues.Add("#camowarfare:add_on_armor_blocks")
$armoredValues.Add("#camowarfare:slat_armor_blocks")
$armoredValues.Add("camowarfare:armor_plate_block")

foreach ($family in $families.Values) {
    foreach ($variant in @("a", "b", "c", "d")) {
        $id = "camowarfare:{0}_{1}_block" -f $family.Id, $variant
        $pickaxeValues.Add($id)
        $armoredValues.Add($id)
    }
    if ($family.Legacy) {
        $legacyId = "camowarfare:{0}" -f $family.Legacy
        $pickaxeValues.Add($legacyId)
        $armoredValues.Add($legacyId)
    }
}

foreach ($alias in $compatAliases) {
    $id = "camowarfare:{0}" -f $alias.Id
    $pickaxeValues.Add($id)
    $armoredValues.Add($id)
}

Save-Json $pickaxeTagPath @{
    replace = $false
    values = @($pickaxeValues | Select-Object -Unique)
}

Save-Json $armoredTagPath @{
    replace = $false
    values = @($armoredValues | Select-Object -Unique)
}

Write-Output "compat alias resources and block tags regenerated"
