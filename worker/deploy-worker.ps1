# warp-masque worker 一键部署（在 worker 目录下运行）
# 用法：powershell -ExecutionPolicy Bypass -File deploy-worker.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Test-Path "./worker")) { Set-Location "../work/warp-masque-actions/worker" }
if (-not (Test-Path "./wrangler.toml")) { Write-Host "找不到 wrangler.toml，请确认在 worker 目录下运行"; exit 1 }

Write-Host "1/4 检查登录状态..."
npx wrangler whoami
if ($LASTEXITCODE -ne 0) {
  Write-Host "未登录，正在打开浏览器登录..."
  npx wrangler login
}

Write-Host "2/4 创建 KV namespace..."
$kvOut = npx wrangler kv namespace create KV 2>&1 | Out-String
Write-Host $kvOut
# 尝试从输出提取 id = "xxxx"
if ($kvOut -match 'id\s*=\s*"([^"]+)"') {
  $kvId = $Matches[1]
  Write-Host "KV id: $kvId"
  $toml = Get-Content ./wrangler.toml -Raw
  if ($toml -match '在这里填你的 KV namespace id') {
    $toml = $toml -replace '在这里填你的 KV namespace id', $kvId
    Set-Content ./wrangler.toml $toml -Encoding UTF8
    Write-Host "已自动写入 wrangler.toml"
  } else {
    Write-Host "wrangler.toml 里已经有 id，请手动确认是否为 $kvId"
  }
} else {
  Write-Host "没能自动解析 KV id，请手动复制上面输出的 id 填到 wrangler.toml"
  exit 1
}

Write-Host "3/4 校验配置..."
npx wrangler check 2>&1 | Out-String -Width 300 | Write-Host

Write-Host "4/4 部署..."
npx wrangler deploy

Write-Host ""
Write-Host "部署完成！打开上面输出的 https://xxx.workers.dev，第一次打开会让你设密码，设完就能用。"
Write-Host "之后在状态页改订阅路径、每4小时自动刷新 WARP/Opera，不用再管。"
