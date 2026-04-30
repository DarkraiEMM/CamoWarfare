$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$blockTextureRoot = Join-Path $root "src\main\resources\assets\camowarfare\textures\block"

$targets = @(
    "naval_bluegray_camo",
    "naval_bluegray_digital",
    "naval_bluegray_splinter",
    "night_lowvis_camo",
    "night_lowvis_digital",
    "night_lowvis_splinter",
    "snow_graywhite_camo",
    "snow_graywhite_digital",
    "snow_graywhite_splinter",
    "urban_gray_camo",
    "urban_gray_digital",
    "urban_gray_splinter"
)

$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class TargetedMetalFinisher
{
    public static int GetStableSeed(string text)
    {
        long hash = 2166136261;
        foreach (char c in text)
        {
            hash = (hash ^ c);
            hash = (hash * 16777619) % 4294967296;
        }
        return (int)(hash & 0x7FFFFFFF);
    }

    private static byte ClampByte(int value)
    {
        if (value < 0) return 0;
        if (value > 255) return 255;
        return (byte)value;
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

                        int clusterGate = Math.Abs((((x / 3) * 19349663) ^ ((y / 3) * 83492791) ^ seed) % 11);
                        int delta = 0;
                        if (clusterGate <= 6)
                        {
                            int scatter = Math.Abs(((x * 73856093) ^ (y * 19349663) ^ seed) % 13);
                            delta = scatter - 6;
                        }
                        else if (clusterGate == 10)
                        {
                            int spark = Math.Abs(((x * 83492791) ^ (y * 265443576) ^ seed) % 9);
                            delta = (spark - 4) * 2;
                        }

                        if (delta > 0)
                            delta = (delta + 1) / 2;
                        else if (delta < 0)
                            delta = delta - 1;

                        // Matte finish: compress highlights slightly while keeping local contrast.
                        int matte = -2;
                        target[index] = ClampByte(source[index] + delta + matte);
                        target[index + 1] = ClampByte(source[index + 1] + delta + matte);
                        target[index + 2] = ClampByte(source[index + 2] + delta + matte);
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

foreach ($target in $targets) {
    $dir = Join-Path $blockTextureRoot $target
    if (-not (Test-Path $dir)) { continue }

    Get-ChildItem -Path $dir -Filter '*.png' | ForEach-Object {
        $relative = $_.FullName.Substring($blockTextureRoot.Length).TrimStart('\')
        [TargetedMetalFinisher]::Process($_.FullName, $relative)
    }
}

Write-Output "metal finish applied to new block families"
