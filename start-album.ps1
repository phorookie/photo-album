# Photo Album - local launcher
# Uses only built-in Windows PowerShell. No Python / Node / admin rights required.
# Serves this folder over http://localhost because IndexedDB is blocked on file://
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition

$mime = @{
  '.html'        = 'text/html; charset=utf-8'
  '.htm'         = 'text/html; charset=utf-8'
  '.js'          = 'application/javascript; charset=utf-8'
  '.css'         = 'text/css; charset=utf-8'
  '.json'        = 'application/json; charset=utf-8'
  '.webmanifest' = 'application/manifest+json; charset=utf-8'
  '.svg'         = 'image/svg+xml'
  '.png'         = 'image/png'
  '.jpg'         = 'image/jpeg'
  '.jpeg'        = 'image/jpeg'
  '.ico'         = 'image/x-icon'
  '.txt'         = 'text/plain; charset=utf-8'
  '.md'          = 'text/plain; charset=utf-8'
}

# ALBUM_LAN=1 binds to all NICs so a phone on the same Wi-Fi can open the album.
# Default binds to loopback only (safer, no firewall prompt).
$lanMode = ($env:ALBUM_LAN -eq '1')
$bindIp  = if ($lanMode) { [Net.IPAddress]::Any } else { [Net.IPAddress]::Loopback }

$listener = $null
$port = 0
foreach ($p in 8080..8090) {
  try {
    $t = New-Object System.Net.Sockets.TcpListener($bindIp, $p)
    $t.Start()
    $listener = $t
    $port = $p
    break
  } catch { }
}

if ($null -eq $listener) {
  Write-Host ''
  Write-Host '  Cannot start: ports 8080-8090 are all in use.' -ForegroundColor Red
  Write-Host '  Close the other program, then double-click this script again.' -ForegroundColor Red
  Write-Host ''
  exit 1
}

$url = "http://localhost:$port/album.html"
Write-Host ''
Write-Host '  ================================================' -ForegroundColor Cyan
Write-Host '   Photo Album is running' -ForegroundColor Cyan
Write-Host "   URL: $url" -ForegroundColor Cyan
Write-Host '   Your browser will open automatically.' -ForegroundColor Cyan
Write-Host '   Close this window when you are done.' -ForegroundColor Cyan
if ($lanMode) {
  $ips = @()
  # Prefer the NIC that owns the default route; this avoids printing VMware/VPN virtual adapters.
  try {
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop |
      Sort-Object RouteMetric | Select-Object -First 1
    if ($route) {
      $ips = @(Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $route.ifIndex -ErrorAction Stop |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
        Select-Object -ExpandProperty IPAddress)
    }
  } catch { }
  if ($ips.Count -eq 0) {
    try {
      $ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
        Select-Object -ExpandProperty IPAddress)
    } catch {
      try {
        $ips = @([Net.Dns]::GetHostAddresses([Net.Dns]::GetHostName()) |
          Where-Object { $_.AddressFamily -eq 'InterNetwork' } |
          ForEach-Object { $_.IPAddressToString })
      } catch { }
    }
  }
  Write-Host ''
  Write-Host '   PHONE (same Wi-Fi):' -ForegroundColor Yellow
  if ($ips.Count -eq 0) {
    Write-Host "   LAN IP not detected. Run ipconfig, then use http://(IPv4):$port/album.html" -ForegroundColor Yellow
  } else {
    foreach ($ip in $ips) { Write-Host "   http://${ip}:$port/album.html" -ForegroundColor Yellow }
  }
  Write-Host '   If Windows Firewall prompts, allow it on PRIVATE networks.' -ForegroundColor Yellow
  Write-Host '   If the phone cannot connect, check both devices are on the SAME Wi-Fi.' -ForegroundColor Yellow
}
Write-Host '  ================================================' -ForegroundColor Cyan
Write-Host ''

if (-not $env:ALBUM_NO_BROWSER) { Start-Process $url }

$rootFull = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'

function Send-Response($stream, $code, $ctype, $bytes) {
  $reason = 'OK'
  if ($code -eq 404) { $reason = 'Not Found' }
  if ($code -eq 403) { $reason = 'Forbidden' }
  $head = "HTTP/1.1 $code $reason`r`nContent-Type: $ctype`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
  $hb = [Text.Encoding]::ASCII.GetBytes($head)
  $stream.Write($hb, 0, $hb.Length)
  if ($bytes.Length -gt 0) { $stream.Write($bytes, 0, $bytes.Length) }
  $stream.Flush()
}

while ($true) {
  $client = $null
  try {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $stream.ReadTimeout = 8000
    $buf = New-Object byte[] 16384
    $n = $stream.Read($buf, 0, $buf.Length)
    if ($n -le 0) { $client.Close(); continue }

    $req = [Text.Encoding]::ASCII.GetString($buf, 0, $n)
    $firstLine = ($req -split "`r`n")[0]
    $parts = $firstLine -split ' '
    $rawPath = '/'
    if ($parts.Length -ge 2) { $rawPath = $parts[1] }
    $rel = [Uri]::UnescapeDataString(($rawPath -split '\?')[0]).TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($rel)) { $rel = 'album.html' }

    $full = [IO.Path]::GetFullPath([IO.Path]::Combine($root, $rel))
    if (-not $full.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
      Send-Response $stream 403 'text/plain; charset=utf-8' @()
      $client.Close(); continue
    }
    if (-not [IO.File]::Exists($full)) {
      $msg = [Text.Encoding]::UTF8.GetBytes('404 Not Found')
      Send-Response $stream 404 'text/plain; charset=utf-8' $msg
      $client.Close(); continue
    }

    $ext = [IO.Path]::GetExtension($full).ToLower()
    $ctype = 'application/octet-stream'
    if ($mime.ContainsKey($ext)) { $ctype = $mime[$ext] }
    $bytes = [IO.File]::ReadAllBytes($full)
    Send-Response $stream 200 $ctype $bytes
  } catch {
  } finally {
    if ($null -ne $client) { try { $client.Close() } catch { } }
  }
}
