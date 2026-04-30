$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$javaPath = Join-Path $root "src\main\java\com\camowarfare\CamoFamily.java"
$blockTextureRoot = Join-Path $root "src\main\resources\assets\camowarfare\textures\block"

$familyIds = @(
    Select-String -Path $javaPath -Pattern '^\s*[A-Z0-9_]+\("([^"]+)",' | ForEach-Object {
        $_.Matches[0].Groups[1].Value
    }
) | Where-Object {
    $_ -and
    ($_ -notmatch '^solid_')
}

$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class ActiveCamoFinisher
{
    public static int GetStableSeed(string text)
    {
        unchecked
        {
            int hash = 23;
            foreach (char c in text)
            {
                hash = (hash * 31) + c;
            }
            return Math.Abs(hash);
        }
    }

    private static byte ClampByte(int value)
    {
        if (value < 0) return 0;
        if (value > 255) return 255;
        return (byte)value;
    }

    private static int GridNoise(int gx, int gy, int seed)
    {
        unchecked
        {
            int value = seed;
            value ^= gx * 374761393;
            value ^= gy * 668265263;
            value = (value ^ (value >> 13)) * 1274126177;
            value ^= (value >> 16);
            return value;
        }
    }

    private static int ShadeAt(int x, int y, int seed)
    {
        int gx = x / 16;
        int gy = y / 16;
        double fx = (x % 16) / 16.0;
        double fy = (y % 16) / 16.0;

        int s00 = (Math.Abs(GridNoise(gx, gy, seed)) % 21) - 10;
        int s10 = (Math.Abs(GridNoise(gx + 1, gy, seed)) % 21) - 10;
        int s01 = (Math.Abs(GridNoise(gx, gy + 1, seed)) % 21) - 10;
        int s11 = (Math.Abs(GridNoise(gx + 1, gy + 1, seed)) % 21) - 10;

        double top = (s00 * (1.0 - fx)) + (s10 * fx);
        double bottom = (s01 * (1.0 - fx)) + (s11 * fx);
        return (int)Math.Round((top * (1.0 - fy)) + (bottom * fy));
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

                        int shade = ShadeAt(x, y, seed);
                        int grainGate = Math.Abs((((x / 2) * 19349663) ^ ((y / 2) * 83492791) ^ seed) % 13);
                        int grain = 0;
                        if (grainGate <= 2) grain = -2;
                        else if (grainGate == 3 || grainGate == 4) grain = -1;
                        else if (grainGate == 10 || grainGate == 11) grain = 1;
                        else if (grainGate == 12) grain = 2;

                        int matte = -2;
                        int brightness = (source[index] + source[index + 1] + source[index + 2]) / 3;
                        int delta = shade + grain + matte;

                        if (brightness > 225 && delta > 4)
                            delta = 4;
                        if (brightness > 238)
                            delta -= 2;
                        if (brightness < 48 && delta < -5)
                            delta = -5;

                        target[index] = ClampByte(source[index] + delta);
                        target[index + 1] = ClampByte(source[index + 1] + delta);
                        target[index + 2] = ClampByte(source[index + 2] + delta);
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

foreach ($familyId in $familyIds) {
    $dir = Join-Path $blockTextureRoot $familyId
    if (-not (Test-Path $dir)) { continue }

    Get-ChildItem -Path $dir -Filter '*.png' | ForEach-Object {
        $relative = $_.FullName.Substring($blockTextureRoot.Length).TrimStart('\')
        [ActiveCamoFinisher]::Process($_.FullName, $relative)
    }
}

Write-Output ("finish applied to {0} active camouflage families" -f $familyIds.Count)
