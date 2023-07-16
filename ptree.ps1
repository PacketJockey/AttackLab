function Get-ProcessAndChildProcesses($Level, $Process) {
  #"{0}{1,-5} {2} {3}" -f ("  " * $Level), $Process.Name, $Process.ProcessId, $Process.ExecutablePath
  "{0}{1,-5} {2} {3} {4}" -f ("|--" * $Level), $Process.Name, $Process.ProcessId, $Process.ExecutablePath, $Process.GetOwnerSid()
  $Children = $Global:Processes | where-object {$_.ParentProcessId -eq $Process.ProcessId -and $_.CreationDate -ge $Process.CreationDate}
  if ($Children -ne $null) {
    foreach ($Child in $Children) {
      Get-ProcessAndChildProcesses ($Level + 2) $Child
    }
  }
}

$Global:Processes = Get-WMIObject -Class Win32_Process
$RootProcesses = @()
# Process "System Idle Process" is processed differently, as ProcessId and ParentProcessId are 0
# $Global:Processes is sliced from index 1 to the end of the array
foreach ($Process in $Global:Processes[1..($Global:Processes.length-1)]) {
  $Parent = $global:Processes | where-object {$_.ProcessId -eq $Process.ParentProcessId -and $_.CreationDate -lt $Process.CreationDate}
  if ($Parent -eq $null) {
    $RootProcesses += $Process
  }
}
#Process the "System Idle process" separately
"[{0,-5}] [{1}]" -f $Global:Processes[0].ProcessId, $Global:Processes[0].Name
foreach ($Process in $RootProcesses) {
  Get-ProcessAndChildProcesses 0 $Process
}