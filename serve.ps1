$root = $PSScriptRoot
$port = 8080
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving at http://localhost:$port/"
Write-Host "  Bengo:     http://localhost:$port/bengo.html"
Write-Host "  Tic Tac Toe: http://localhost:$port/tictactoe.html"
Write-Host "Press Ctrl+C to stop."

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".png"  = "image/png"
    ".ico"  = "image/x-icon"
}

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $req = $ctx.Request
        $res = $ctx.Response

        $urlPath = $req.Url.AbsolutePath
        if ($urlPath -eq "/") { $urlPath = "/index.html" }
        $filePath = Join-Path $root $urlPath.TrimStart("/")

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath)
            $mime = if ($mimeTypes[$ext]) { $mimeTypes[$ext] } else { "application/octet-stream" }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $res.ContentType = $mime
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            # Directory listing for /
            if ($req.Url.AbsolutePath -eq "/") {
                $body = "<html><body><h2>Games</h2><ul><li><a href='/bengo.html'>Bengo Platformer</a></li><li><a href='/tictactoe.html'>Tic Tac Toe</a></li></ul></body></html>"
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
                $res.ContentType = "text/html; charset=utf-8"
                $res.ContentLength64 = $bytes.Length
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $res.StatusCode = 404
                $bytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
                $res.ContentLength64 = $bytes.Length
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        }
        $res.OutputStream.Close()
    }
} finally {
    $listener.Stop()
}
