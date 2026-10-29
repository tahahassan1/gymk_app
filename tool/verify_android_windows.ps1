param(
  [Parameter(Mandatory = $true)][string]$DeviceId,
  [string]$Adb = 'E:/Programs/Android/platform-tools/adb.exe',
  [string]$Log = 'build/verification/phase8-os-windows.log'
)
$ErrorActionPreference = 'Stop'
if ($DeviceId -ne 'emulator-5556') {
  throw 'This fixture script is restricted to the separately owned emulator-5556.'
}
$outputDirectory = Join-Path (Get-Location) 'build/verification/screenshots'
New-Item -ItemType Directory -Force $outputDirectory | Out-Null
$originalSize = & $Adb -s $DeviceId shell wm size
$originalDensity = & $Adb -s $DeviceId shell wm density
$originalScale = (& $Adb -s $DeviceId shell settings get system font_scale).Trim()
$originalRotation = (& $Adb -s $DeviceId shell settings get system user_rotation).Trim()
$originalAutoRotate = (& $Adb -s $DeviceId shell settings get system accelerometer_rotation).Trim()
function Device([string[]]$Arguments) {
  & $Adb -s $DeviceId @Arguments | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "adb failed: $Arguments" }
}
function Wait-Marker([string]$Marker) {
  $deadline = (Get-Date).AddMinutes(8)
  do {
    $content = if (Test-Path -LiteralPath $Log) { Get-Content -LiteralPath $Log -Raw } else { '' }
    if ($content.Contains($Marker)) { return }
    if ($content.Contains('[E]') -or $content.Contains('Some tests failed')) {
      throw "Native test failed before $Marker; inspect $Log"
    }
    Start-Sleep -Milliseconds 200
  } while ((Get-Date) -lt $deadline)
  throw "Timed out waiting for $Marker"
}
function App-Task {
  $tasks = (& $Adb -s $DeviceId shell dumpsys activity activities) -join "`n"
  $match = [regex]::Match($tasks, 'Task\{[^\r\n]*?#(\d+)[^\r\n]*dev\.tahahassan\.gymk')
  if (!$match.Success) { throw 'Cannot locate the Gymk activity task.' }
  return $match.Groups[1].Value
}
function App-StageTask {
  $parents = @{}
  $tasks = & $Adb -s $DeviceId shell dumpsys activity activities
  foreach ($line in $tasks) {
    $match = [regex]::Match($line, '^(\s*)\* Task\{[^\r\n]*?#(\d+)')
    if (!$match.Success) { continue }
    $depth = $match.Groups[1].Value.Length
    if ($line.Contains('I=dev.tahahassan.gymk/.MainActivity')) {
      $parentDepth = $parents.Keys | Where-Object { $_ -lt $depth } | Sort-Object -Descending | Select-Object -First 1
      if ($null -eq $parentDepth) { throw 'Cannot locate the split stage parent.' }
      return $parents[$parentDepth]
    }
    $parents[$depth] = $match.Groups[2].Value
  }
  throw 'Cannot locate the Gymk split stage.'
}
try {
  Device @('forward', 'tcp:19876', 'tcp:9876')
  Device @('shell', 'settings', 'put', 'system', 'accelerometer_rotation', '0')
  Device @('shell', 'wm', 'density', '160')
  foreach ($stage in @('phone', 'width599', 'width600', 'width601', 'tablet', 'keyboard', 'largeText', 'landscape', 'split', 'wideSplit')) {
    Wait-Marker "GYMK_WINDOW_REQUEST $stage"
    $size = switch ($stage) {
      'phone' { '390x840' }
      'width599' { '599x1000' }
      'width600' { '600x1000' }
      'width601' { '601x1000' }
      'landscape' { '390x840' }
      'wideSplit' { '2048x1000' }
      default { '1024x1000' }
    }
    $rotation = if ($stage -eq 'landscape') { '1' } else { '0' }
    $scale = if ($stage -in @('largeText', 'landscape')) { '2.0' } else { '1.0' }
    Device @('shell', 'settings', 'put', 'system', 'font_scale', $scale)
    Device @('shell', 'settings', 'put', 'system', 'user_rotation', $rotation)
    Device @('shell', 'wm', 'size', $size)
    if ($stage -eq 'keyboard') {
      $testLog = Get-Content -LiteralPath $Log -Raw
      $point = [regex]::Match($testLog, 'GYMK_WINDOW_KEYBOARD (\d+) (\d+)')
      if (!$point.Success) { throw 'Missing native field coordinates.' }
      Device @('shell', 'input', 'tap', $point.Groups[1].Value, $point.Groups[2].Value)
    }
    if ($stage -eq 'split') {
      $task = App-Task
      Device @('shell', 'am', 'start', '-a', 'android.settings.SETTINGS')
      Device @('shell', 'dumpsys', 'activity', 'service', 'com.android.systemui/.SystemUIService', 'WMShell', 'splitscreen', 'moveToSideStage', $task, '0')
    }
    if ($stage -eq 'wideSplit') {
      # Android 36's diagnostic split entry retains explicit stage bounds.
      # Resize the actual Android stage as well as the display, without a
      # Flutter view override or restarting/reparenting the application.
      $stageTask = App-StageTask
      Device @('shell', 'am', 'task', 'resize', $stageTask, '0', '0', '1019', '1000')
    }
    Wait-Marker "GYMK_WINDOW_CAPTURE $stage "
    $windows = (& $Adb -s $DeviceId shell dumpsys window windows) -join "`n"
    if ($windows -match 'Application Not Responding|Application Error') {
      throw 'An Android system/application error dialog obstructs visual verification.'
    }
    Start-Sleep -Milliseconds 1200
    $capturePath = Join-Path $outputDirectory "$stage.png"
    $expected = if ($stage -eq 'landscape') { @(840, 390) } else { $size.Split('x') }
    $captureDeadline = (Get-Date).AddSeconds(15)
    do {
      Device @('shell', 'screencap', '-p', "/sdcard/gymk-$stage.png")
      Device @('pull', "/sdcard/gymk-$stage.png", $capturePath)
      $png = [IO.File]::ReadAllBytes($capturePath)
      $widthBytes = $png[16..19]
      $heightBytes = $png[20..23]
      [Array]::Reverse($widthBytes)
      [Array]::Reverse($heightBytes)
      $imageWidth = [BitConverter]::ToInt32($widthBytes, 0)
      $imageHeight = [BitConverter]::ToInt32($heightBytes, 0)
      $correctSize = $imageWidth -eq [int]$expected[0] -and $imageHeight -eq [int]$expected[1]
      if (!$correctSize) { Start-Sleep -Milliseconds 250 }
    } while (!$correctSize -and (Get-Date) -lt $captureDeadline)
    if (!$correctSize) { throw "Compositor screenshot has stale size: ${imageWidth}x$imageHeight" }
    Device @('shell', 'rm', "/sdcard/gymk-$stage.png")
    Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:19876/ack?id=$stage" | Out-Null
    Write-Output "Captured $stage"
  }
  Wait-Marker 'GYMK_WINDOWS_VERIFIED'
} finally {
  & $Adb -s $DeviceId shell wm size reset | Out-Null
  & $Adb -s $DeviceId shell wm density reset | Out-Null
  if (($originalSize -join ' ') -match 'Override size: (\d+x\d+)') {
    & $Adb -s $DeviceId shell wm size $Matches[1] | Out-Null
  }
  if (($originalDensity -join ' ') -match 'Override density: (\d+)') {
    & $Adb -s $DeviceId shell wm density $Matches[1] | Out-Null
  }
  & $Adb -s $DeviceId shell settings put system font_scale $originalScale | Out-Null
  & $Adb -s $DeviceId shell settings put system user_rotation $originalRotation | Out-Null
  & $Adb -s $DeviceId shell settings put system accelerometer_rotation $originalAutoRotate | Out-Null
  & $Adb -s $DeviceId forward --remove tcp:19876 | Out-Null
}
