$ErrorActionPreference = 'Stop'

$dll = 'C:\users\mrgre\victory-7900XTX\target\diag\D3D12\D3D12Core.dll'
$log = 'C:\Users\mrgre\AppData\Local\Temp\opencode\sm66-probe-agility-1.620.2.log'
$probeId = 'sm66-probe-agility-1.620.2'

$source = @'
using System;
using System.Runtime.InteropServices;

public static class AgilitySm66Probe
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadLibrary(string lpFileName);

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    private static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool FreeLibrary(IntPtr hModule);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate int D3D12GetInterfaceDelegate(ref Guid clsid, ref Guid riid, out IntPtr ppv);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate int CreateDeviceDelegate(IntPtr self, IntPtr adapter, int featureLevel, ref Guid riid, out IntPtr ppvDevice);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate int CheckFeatureSupportDelegate(IntPtr self, int feature, IntPtr data, int dataSize);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate uint ReleaseDelegate(IntPtr self);

    public static string Run(string dllPath)
    {
        IntPtr module = LoadLibrary(dllPath);
        if (module == IntPtr.Zero)
            return "load_library_failed=0x" + Marshal.GetLastWin32Error().ToString("X8");

        try
        {
            IntPtr getInterfacePtr = GetProcAddress(module, "D3D12GetInterface");
            if (getInterfacePtr == IntPtr.Zero)
                return "get_proc_address_failed=0x" + Marshal.GetLastWin32Error().ToString("X8");

            IntPtr sdkVersionPtr = GetProcAddress(module, "D3D12SDKVersion");
            int sdkVersion = sdkVersionPtr == IntPtr.Zero ? -1 : Marshal.ReadInt32(sdkVersionPtr);

            var getInterface = (D3D12GetInterfaceDelegate)Marshal.GetDelegateForFunctionPointer(
                getInterfacePtr, typeof(D3D12GetInterfaceDelegate));

            Guid clsidFactory = new Guid("114863bf-c386-4aee-b39d-8f0bbb062955");
            Guid iidFactory = new Guid("61f307d3-d34e-4e7c-8374-3ba4de23cccb");
            IntPtr factory = IntPtr.Zero;
            int hr = getInterface(ref clsidFactory, ref iidFactory, out factory);
            if (hr < 0)
                return "sdk_export=" + sdkVersion + " get_interface_failed=0x" + hr.ToString("X8");

            try
            {
                IntPtr factoryVtbl = Marshal.ReadIntPtr(factory);
                IntPtr createDevicePtr = Marshal.ReadIntPtr(factoryVtbl, 9 * IntPtr.Size);
                var createDevice = (CreateDeviceDelegate)Marshal.GetDelegateForFunctionPointer(
                    createDevicePtr, typeof(CreateDeviceDelegate));

                Guid iidDevice = new Guid("189819f1-1db6-4b57-be54-1821339b85f7");
                IntPtr device = IntPtr.Zero;
                hr = createDevice(factory, IntPtr.Zero, 0xC000, ref iidDevice, out device);
                if (hr < 0)
                    return "sdk_export=" + sdkVersion + " create_device_failed=0x" + hr.ToString("X8");

                try
                {
                    IntPtr deviceVtbl = Marshal.ReadIntPtr(device);
                    IntPtr checkFeaturePtr = Marshal.ReadIntPtr(deviceVtbl, 13 * IntPtr.Size);
                    var checkFeature = (CheckFeatureSupportDelegate)Marshal.GetDelegateForFunctionPointer(
                        checkFeaturePtr, typeof(CheckFeatureSupportDelegate));

                    IntPtr modelData = Marshal.AllocHGlobal(4);
                    IntPtr optionsData = Marshal.AllocHGlobal(8);
                    try
                    {
                        Marshal.WriteInt32(modelData, 0x66);
                        for (int offset = 0; offset < 8; offset += 4)
                            Marshal.WriteInt32(optionsData, offset, 0);

                        int hrModel = checkFeature(device, 7, modelData, 4);
                        int highestShaderModel = Marshal.ReadInt32(modelData);
                        int hrOptions = checkFeature(device, 32, optionsData, 8);
                        int meshShaderTier = Marshal.ReadInt32(optionsData, 0);
                        int samplerFeedbackTier = Marshal.ReadInt32(optionsData, 4);

                        return "sdk_export=" + sdkVersion
                            + " model_hr=0x" + hrModel.ToString("X8")
                            + " highest_shader_model=0x" + highestShaderModel.ToString("X2")
                            + " options7_hr=0x" + hrOptions.ToString("X8")
                            + " mesh_shader_tier=" + meshShaderTier
                            + " sampler_feedback_tier=" + samplerFeedbackTier;
                    }
                    finally
                    {
                        Marshal.FreeHGlobal(modelData);
                        Marshal.FreeHGlobal(optionsData);
                    }
                }
                finally
                {
                    ReleaseCom(device);
                }
            }
            finally
            {
                ReleaseCom(factory);
            }
        }
        finally
        {
            FreeLibrary(module);
        }
    }

    private static void ReleaseCom(IntPtr instance)
    {
        if (instance == IntPtr.Zero)
            return;
        IntPtr vtbl = Marshal.ReadIntPtr(instance);
        IntPtr releasePtr = Marshal.ReadIntPtr(vtbl, 2 * IntPtr.Size);
        var release = (ReleaseDelegate)Marshal.GetDelegateForFunctionPointer(releasePtr, typeof(ReleaseDelegate));
        release(instance);
    }
}
'@

Add-Type -TypeDefinition $source -Language CSharp

$lines = [System.Collections.Generic.List[string]]::new()
function Write-Line([string]$text) {
    $line = "$(Get-Date -Format o) $text"
    Write-Host $line
    $lines.Add($line)
}

$item = Get-Item -LiteralPath $dll
$hash = (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash
Write-Line "probe_id=$probeId"
Write-Line "dll=$dll"
Write-Line "dll_product_version=$($item.VersionInfo.ProductVersion)"
Write-Line "dll_file_version=$($item.VersionInfo.FileVersion)"
Write-Line "dll_sha256=$hash"
Write-Line "note=direct D3D12Core.dll device probe; no victory.exe or game process started"
Write-Line ([AgilitySm66Probe]::Run($dll))

$procs = @(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -eq 'victory.exe' -or $_.Name -eq 'game_scarlett_master.exe'
} | ForEach-Object { "$($_.ProcessId):$($_.Name)" })
Write-Line "post_probe_scoped_processes=$($procs.Count)"
if ($procs.Count -gt 0) {
    Write-Line "post_probe_scoped_process_list=$($procs -join ',')"
}

[System.IO.File]::WriteAllLines($log, $lines)
