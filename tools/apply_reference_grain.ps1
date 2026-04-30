param(
    [string[]]$FamilyIds
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$blockTextureRoot = Join-Path $root "src\main\resources\assets\camowarfare\textures\block"

$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CamoReferenceGrain
{
    public static int GetStableSeed(string text)
    {
        unchecked
        {
            int hash = (int)2166136261;
            foreach (char c in text)
            {
                hash ^= c;
                hash *= 16777619;
            }
            return hash & 0x7fffffff;
        }
    }

    private static byte ClampByte(int value)
    {
        if (value < 0) return 0;
        if (value > 255) return 255;
        return (byte)value;
    }

    private static int Hash(int x, int y, int seed)
    {
        unchecked
        {
            int value = seed;
            value ^= x * 374761393;
            value = (value << 13) ^ value;
            value += y * 668265263;
            value = (value << 11) ^ value;
            return value & 0x7fffffff;
        }
    }

    public static void Process(string path, string relativePath)
    {
        int seed = GetStableSeed(relativePath);
        string tempPath = path + ".tmp.png";

        using (var bitmap = (Bitmap)Image.FromFile(path))
        {
            var rect = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
            var data = bitmap.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            try
            {
                int stride = Math.Abs(data.Stride);
                int length = stride * bitmap.Height;
                byte[] source = new byte[length];
                byte[] target = new byte[length];
                Marshal.Copy(data.Scan0, source, 0, length);
                Buffer.BlockCopy(source, 0, target, 0, length);

                for (int y = 0; y < bitmap.Height; y++)
                {
                    int row = y * stride;
                    for (int x = 0; x < bitmap.Width; x++)
                    {
                        int index = row + (x * 4);
                        byte alpha = source[index + 3];
                        if (alpha == 0)
                            continue;

                        int micro = (Hash(x, y, seed) % 7) - 3;
                        int grainGate = Hash(x + 19, y - 11, seed) % 100;
                        if (grainGate < 22)
                            micro = 0;
                        else if (grainGate < 70)
                            micro = Math.Sign(micro);

                        int cell = (Hash(x / 6, y / 6, seed ^ 0x5a5a5a5a) % 5) - 2;
                        int band = (Hash(x / 16, y / 16, seed ^ 0x13572468) % 3) - 1;
                        int delta = micro + cell + band;

                        int blue = source[index];
                        int green = source[index + 1];
                        int red = source[index + 2];
                        int brightness = (red + green + blue) / 3;

                        if (brightness > 210 && delta < -2)
                            delta = -2;
                        if (brightness < 40 && delta > 2)
                            delta = 2;

                        target[index] = ClampByte(blue + delta);
                        target[index + 1] = ClampByte(green + delta);
                        target[index + 2] = ClampByte(red + delta);
                    }
                }

                Marshal.Copy(target, 0, data.Scan0, length);
            }
            finally
            {
                bitmap.UnlockBits(data);
            }

            bitmap.Save(tempPath, ImageFormat.Png);
        }

        if (System.IO.File.Exists(path))
            System.IO.File.Delete(path);
        System.IO.File.Move(tempPath, path);
    }
}
"@

Add-Type -TypeDefinition $csharp -ReferencedAssemblies "System.Drawing"

$textureFiles = @()
$textureFiles += Get-ChildItem -Path $blockTextureRoot -Filter '*.png'

if ($FamilyIds -and $FamilyIds.Count -gt 0) {
    foreach ($familyId in $FamilyIds) {
        $familyDir = Join-Path $blockTextureRoot $familyId
        if (Test-Path $familyDir) {
            $textureFiles += Get-ChildItem -Path $familyDir -Filter '*.png'
        }
    }
}
else {
    $familyDirs = Get-ChildItem -Path $blockTextureRoot -Directory
    foreach ($dir in $familyDirs) {
        $textureFiles += Get-ChildItem -Path $dir.FullName -Filter '*.png'
    }
}

$textureFiles |
    Sort-Object FullName |
    ForEach-Object {
        $relative = $_.FullName.Substring($blockTextureRoot.Length).TrimStart('\')
        [CamoReferenceGrain]::Process($_.FullName, $relative)
    }

Write-Output "reference grain applied"
