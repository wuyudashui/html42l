$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$Port = 8770

# ---- 找一个**真正能跑**的 Python ----
# 只判断命令存在是不够的：本机 py 启动器存在，但它指向的
# F:\python\python.exe 已经不存在，一调用就报错退出。
# 所以每个候选都要实际执行一次再决定。
function Find-PythonExe {
    $candidates = @(
        @{ Exe = 'py';      Args = @('-3') },
        @{ Exe = 'python';  Args = @() },
        @{ Exe = 'D:\Anaconda\envs\guandan\python.exe'; Args = @() },
        @{ Exe = (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python311\python.exe'); Args = @() },
        @{ Exe = (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'); Args = @() }
    )
    foreach ($c in $candidates) {
        if (-not (Get-Command $c.Exe -ErrorAction SilentlyContinue) -and
            -not (Test-Path -LiteralPath $c.Exe)) { continue }
        try {
            $out = & $c.Exe @($c.Args) -c "import sys;print(sys.version.split()[0])" 2>$null
            if ($LASTEXITCODE -eq 0 -and $out) {
                return @{ Exe = $c.Exe; Args = $c.Args; Version = ([string]$out).Trim() }
            }
        } catch {
            # 这个候选不可用，继续试下一个
        }
    }
    return $null
}

$py = Find-PythonExe
if (-not $py) {
    Write-Host ''
    Write-Host '[错误] 没找到可用的 Python，无法启动本地服务。' -ForegroundColor Red
    Write-Host '备选方案：把 index.html 和 assets 整个文件夹上传到任意静态托管'
    Write-Host '          (GitHub Pages / Vercel / 自己的服务器)，手机访问那个网址。'
    Write-Host ''
    Read-Host '按回车退出'
    exit 1
}

$ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
    Select-Object -ExpandProperty IPAddress)

Write-Host ('使用 Python: {0}  (版本 {1})' -f $py.Exe, $py.Version) -ForegroundColor DarkGray
Write-Host ('服务端口:    {0}' -f $Port) -ForegroundColor DarkGray
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  手机怎么打开这个页面' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host '  1) 手机与这台电脑连同一个 Wi-Fi'
Write-Host '  2) 在手机浏览器里打开下面任意一个地址：'
Write-Host ''
if ($ips.Count -eq 0) {
    Write-Host '        未检测到局域网地址，请确认 Wi-Fi 已连接' -ForegroundColor Yellow
} else {
    foreach ($ip in $ips) {
        Write-Host ('        http://{0}:{1}/' -f $ip, $Port) -ForegroundColor Green
    }
}
Write-Host ''
Write-Host '  3) 打不开时依次检查：'
Write-Host '       - Windows 防火墙弹窗要选「允许访问」'
Write-Host '       - 网络类型设为「专用网络」而不是「公用网络」'
Write-Host '       - 路由器是否开了「AP 隔离 / 客户端隔离」（开了就不通）'
Write-Host ''
Write-Host '  这个窗口不要关，关掉服务就停了。按 Ctrl+C 停止。' -ForegroundColor DarkGray
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''

try {
    & $py.Exe @($py.Args) -m http.server $Port --bind 0.0.0.0
} catch {
    Write-Host ''
    Write-Host ('启动失败：{0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ('如果提示端口被占用，改本脚本顶部的 $Port 再试。') -ForegroundColor Yellow
    Read-Host '按回车退出'
    exit 1
}
