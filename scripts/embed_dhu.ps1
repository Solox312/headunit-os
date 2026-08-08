# Embeds Google's official Desktop Head Unit (DHU) window directly inside HeadUnit OS
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    [DllImport("user32.dll")] public static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr hWnd, int nIndex, uint dwNewLong);
}
"@

$dhuHwnd = [Win32]::FindWindow($null, "Android Auto - Desktop Head Unit")
$flutterHwnd = [Win32]::FindWindow($null, "rpi_headunit")

if ($dhuHwnd -ne [IntPtr]::Zero -and $flutterHwnd -ne [IntPtr]::Zero) {
    [Win32]::SetParent($dhuHwnd, $flutterHwnd)
    # Move DHU window into the projection canvas area
    [Win32]::MoveWindow($dhuHwnd, 180, 70, 1080, 680, $true)
    Write-Host "Successfully embedded Google Android Auto DHU into HeadUnit OS!"
} else {
    Write-Host "DHU Window or HeadUnit OS window not found."
}
