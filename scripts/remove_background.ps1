param (
    [string]$InputPath,
    [string]$OutputPath,
    [int]$Tolerance = 25
)

$csharpCode = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class ImageProcessor {
    public static void RemoveBackground(string inputPath, string outputPath, int tolerance) {
        byte[] bytes = System.IO.File.ReadAllBytes(inputPath);
        using (var ms = new System.IO.MemoryStream(bytes))
        using (var src = new Bitmap(ms)) {
            int w = src.Width;
            int h = src.Height;

            Bitmap dest = new Bitmap(w, h, PixelFormat.Format32bppArgb);

            BitmapData srcData = src.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            BitmapData dstData = dest.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);

            int stride = srcData.Stride;
            int totalBytes = Math.Abs(stride) * h;
            byte[] pixelBuffer = new byte[totalBytes];
            byte[] outBuffer = new byte[totalBytes];

            System.Runtime.InteropServices.Marshal.Copy(srcData.Scan0, pixelBuffer, 0, totalBytes);
            Array.Copy(pixelBuffer, outBuffer, totalBytes);

            byte bgB = pixelBuffer[0];
            byte bgG = pixelBuffer[1];
            byte bgR = pixelBuffer[2];

            bool[,] visited = new bool[w, h];
            Queue<Point> queue = new Queue<Point>();

            Func<int, int, bool> isBg = (x, y) => {
                int idx = y * stride + x * 4;
                int b = pixelBuffer[idx];
                int g = pixelBuffer[idx + 1];
                int r = pixelBuffer[idx + 2];
                return Math.Abs(r - bgR) <= tolerance && Math.Abs(g - bgG) <= tolerance && Math.Abs(b - bgB) <= tolerance;
            };

            for (int x = 0; x < w; x++) {
                if (isBg(x, 0)) { visited[x, 0] = true; queue.Enqueue(new Point(x, 0)); }
                if (isBg(x, h - 1)) { visited[x, h - 1] = true; queue.Enqueue(new Point(x, h - 1)); }
            }
            for (int y = 0; y < h; y++) {
                if (!visited[0, y] && isBg(0, y)) { visited[0, y] = true; queue.Enqueue(new Point(0, y)); }
                if (!visited[w - 1, y] && isBg(w - 1, y)) { visited[w - 1, y] = true; queue.Enqueue(new Point(w - 1, y)); }
            }

            int[] dx = { 1, -1, 0, 0 };
            int[] dy = { 0, 0, 1, -1 };

            while (queue.Count > 0) {
                Point p = queue.Dequeue();
                int idx = p.Y * stride + p.X * 4;
                outBuffer[idx + 3] = 0; // Alpha 0

                for (int i = 0; i < 4; i++) {
                    int nx = p.X + dx[i];
                    int ny = p.Y + dy[i];
                    if (nx >= 0 && nx < w && ny >= 0 && ny < h && !visited[nx, ny]) {
                        if (isBg(nx, ny)) {
                            visited[nx, ny] = true;
                            queue.Enqueue(new Point(nx, ny));
                        }
                    }
                }
            }

            src.UnlockBits(srcData);
            System.Runtime.InteropServices.Marshal.Copy(outBuffer, 0, dstData.Scan0, totalBytes);
            dest.UnlockBits(dstData);

            dest.Save(outputPath, ImageFormat.Png);
            dest.Dispose();
        }
    }
}
"@

Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies "System.Drawing.dll"
[ImageProcessor]::RemoveBackground($InputPath, $OutputPath, $Tolerance)
Write-Output "PNG transparente salvo com alta precisao em: $OutputPath"
