param(
    [Parameter(Mandatory = $true)][string]$SdkDir,
    [Parameter(Mandatory = $true)][uint32]$SdkVersion,
    [Parameter(Mandatory = $true)][string]$Log,
    [string]$ProbeId = 'd3d12-features'
)

$ErrorActionPreference = 'Stop'

$coreDll = Join-Path $SdkDir 'D3D12Core.dll'

$source = @'
using System;
using System.Runtime.InteropServices;

public static class D3D12FeatureProbe
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
    private delegate int CreateDeviceFactoryDelegate(IntPtr self, uint sdkVersion,
        [MarshalAs(UnmanagedType.LPStr)] string sdkPath, ref Guid riid, out IntPtr ppvFactory);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate int CreateDeviceDelegate(IntPtr self, IntPtr adapter, int featureLevel,
        ref Guid riid, out IntPtr ppvDevice);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate int CheckFeatureSupportDelegate(IntPtr self, int feature, IntPtr data, int dataSize);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate uint ReleaseDelegate(IntPtr self);

    public static string Run(string sdkPath, uint sdkVersion, string coreDll)
    {
        IntPtr module = LoadLibrary("d3d12.dll");
        if (module == IntPtr.Zero)
            return "load_system_d3d12_failed=0x" + Marshal.GetLastWin32Error().ToString("X8");

        try
        {
            IntPtr getInterfacePtr = GetProcAddress(module, "D3D12GetInterface");
            if (getInterfacePtr == IntPtr.Zero)
                return "get_proc_address_failed=0x" + Marshal.GetLastWin32Error().ToString("X8");

            var getInterface = (D3D12GetInterfaceDelegate)Marshal.GetDelegateForFunctionPointer(
                getInterfacePtr, typeof(D3D12GetInterfaceDelegate));

            Guid clsidConfig = new Guid("7cda6aca-a03e-49c8-9458-0334d20e07ce");
            Guid iidConfig1 = new Guid("8aaf9303-ad25-48b9-9a57-d9c37e009d9f");
            IntPtr config = IntPtr.Zero;
            int hr = getInterface(ref clsidConfig, ref iidConfig1, out config);
            if (hr < 0)
                return "sdk_configuration_query_failed=0x" + hr.ToString("X8");

            try
            {
                IntPtr configVtbl = Marshal.ReadIntPtr(config);
                IntPtr createFactoryPtr = Marshal.ReadIntPtr(configVtbl, 4 * IntPtr.Size);
                var createFactory = (CreateDeviceFactoryDelegate)Marshal.GetDelegateForFunctionPointer(
                    createFactoryPtr, typeof(CreateDeviceFactoryDelegate));

                Guid iidFactory = new Guid("61f307d3-d34e-4e7c-8374-3ba4de23cccb");
                IntPtr factory = IntPtr.Zero;
                hr = createFactory(config, sdkVersion, sdkPath, ref iidFactory, out factory);
                if (hr < 0)
                    return "create_device_factory_failed=0x" + hr.ToString("X8");

                try
                {
                    IntPtr core = LoadLibrary(coreDll);
                    int sdkExport = -1;
                    if (core != IntPtr.Zero)
                    {
                        IntPtr sdkPtr = GetProcAddress(core, "D3D12SDKVersion");
                        if (sdkPtr != IntPtr.Zero)
                            sdkExport = Marshal.ReadInt32(sdkPtr);
                        FreeLibrary(core);
                    }

                    IntPtr factoryVtbl = Marshal.ReadIntPtr(factory);
                    IntPtr createDevicePtr = Marshal.ReadIntPtr(factoryVtbl, 9 * IntPtr.Size);
                    var createDevice = (CreateDeviceDelegate)Marshal.GetDelegateForFunctionPointer(
                        createDevicePtr, typeof(CreateDeviceDelegate));

                    Guid iidDevice = new Guid("189819f1-1db6-4b57-be54-1821339b85f7");
                    IntPtr device = IntPtr.Zero;
                    hr = createDevice(factory, IntPtr.Zero, 0xC000, ref iidDevice, out device);
                    if (hr < 0)
                        return "sdk_export=" + sdkExport + " create_device_failed=0x" + hr.ToString("X8");

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

                            return "sdk_export=" + sdkExport
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
                ReleaseCom(config);
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

$item = Get-Item -LiteralPath $coreDll
$hash = (Get-FileHash -LiteralPath $coreDll -Algorithm SHA256).Hash
Write-Line "probe_id=$ProbeId"
Write-Line "sdk_dir=$SdkDir"
Write-Line "sdk_requested=$SdkVersion"
Write-Line "core_dll=$coreDll"
Write-Line "core_product_version=$($item.VersionInfo.ProductVersion)"
Write-Line "core_sha256=$hash"
Write-Line "note=read-only device probe; no victory.exe or game process launched by this probe"
Write-Line ([D3D12FeatureProbe]::Run($SdkDir, $SdkVersion, $coreDll))

[System.IO.File]::WriteAllLines($Log, $lines)
