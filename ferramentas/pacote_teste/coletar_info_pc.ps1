# Junta as informacoes do PC num arquivo info_pc.txt nesta pasta. So le, nao muda nada.
$pasta = Split-Path -Parent $MyInvocation.MyCommand.Path
$s = @()
$s += '=== PC do Matheus ==='
$s += 'Data: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')
$os = Get-CimInstance Win32_OperatingSystem
$s += 'Windows: ' + $os.Caption + ' ' + $os.Version
foreach ($p in Get-CimInstance Win32_Processor) {
  $s += 'Processador: ' + $p.Name.Trim() + ' (' + $p.NumberOfCores + ' nucleos, ' + $p.NumberOfLogicalProcessors + ' threads)'
}
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
$s += 'Memoria RAM: ' + $ram + ' GB'
foreach ($v in Get-CimInstance Win32_VideoController) {
  $s += 'Placa de video: ' + $v.Name + ' | driver ' + $v.DriverVersion + ' | ' + $v.CurrentHorizontalResolution + 'x' + $v.CurrentVerticalResolution + ' a ' + $v.CurrentRefreshRate + ' Hz'
}
$s | Out-File -Encoding utf8 (Join-Path $pasta 'info_pc.txt')
$s
