$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$blockTextureRoot = Join-Path $root "src\main\resources\assets\camowarfare\textures\block"

$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CamoMetalFinisher
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

                        int coarseHash = Math.Abs((((x / 4) * 19349663) ^ ((y / 4) * 83492791) ^ seed) % 7);
                        int coarseDelta = coarseHash - 3;

                        int fineGate = Math.Abs(((x * 73856093) ^ (y * 19349663) ^ seed) % 12);
                        int fineDelta = 0;
                        if (fineGate <= 6)
                        {
                            int scatter = Math.Abs(((x * 83492791) ^ (y * 265443576) ^ seed) % 9);
                            fineDelta = scatter - 4;
                        }
                        else if (fineGate == 11)
                        {
                            int spark = Math.Abs(((x * 4256249) ^ (y * 26544357) ^ seed) % 7);
                            fineDelta = spark - 3;
                        }

                        int delta = coarseDelta + fineDelta;
                        if (delta > 0)
                            delta = (delta + 1) / 2;
                        else if (delta < 0)
                            delta = delta - 1;

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

$textureFiles = @()
$textureFiles += Get-ChildItem -Path $blockTextureRoot -Filter '*.png'
$familyDirs = Get-ChildItem -Path $blockTextureRoot -Directory
foreach ($dir in $familyDirs) {
    $textureFiles += Get-ChildItem -Path $dir.FullName -Filter '*.png'
}

$textureFiles | ForEach-Object {
        try {
            $relative = $_.FullName.Substring($blockTextureRoot.Length).TrimStart('\')
            [CamoMetalFinisher]::Process($_.FullName, $relative)
        }
        catch {
            Write-Warning ("Skipped locked texture: " + $_.FullName)
        }
}

Write-Output "metal finish applied"
