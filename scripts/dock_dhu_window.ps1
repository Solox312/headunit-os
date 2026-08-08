# Docks the live Google Android Auto DHU window directly inside HeadUnit OS viewport

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class WindowDock {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);

    public static IntPtr dhuHwnd = IntPtr.Zero;
    public static IntPtr flutterHwnd = IntPtr.Zero;

    public static bool EnumWindowCallback(IntPtr hWnd, IntPtr lParam) {
        if (!IsWindowVisible(hWnd)) return true;
        StringBuilder sb = new StringBuilder(256);
        GetWindowText(hWnd, sb, 256);
        string title = sb.ToString();

        if (title.Length > 0) {
            Console.WriteLine("Window: " + title + " (HWND: " + hWnd + ")");
        }

        if (title.Contains("Android Auto") || title.Contains("Desktop Head Unit")) {
            dhuHwnd = hWnd;
        }
        if (title.Contains("rpi_headunit") || title.Contains("HeadUnit OS") || title.Contains("Flutter")) {
            flutterHwnd = hWnd;
        }
        return true;
    }

    public static bool Dock() {
        dhuHwnd = IntPtr.Zero;
        flutterHwnd = IntPtr.Zero;
        EnumWindows(EnumWindowCallback, IntPtr.Zero);

        if (dhuHwnd != IntPtr.Zero && flutterHwnd != IntPtr.Zero) {
            SetParent(dhuHwnd, flutterHwnd);
            MoveWindow(dhuHwnd, 195, 75, 1050, 620, true);
            Console.WriteLine("SUCCESS: Live Google Android Auto window docked inside HeadUnit OS!");
            return true;
        }
        return false;
    }
}
"@

[WindowDock]::Dock()
