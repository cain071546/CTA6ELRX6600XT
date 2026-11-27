using System;
using System.Reflection;
using System.Threading;

class PressA {
    static void Main(string[] args) {
        var delay = args.Length > 0 ? int.Parse(args[0]) : 0;
        var hold = args.Length > 1 ? int.Parse(args[1]) : 250;
        if (delay > 0) Thread.Sleep(delay);
        var asm = Assembly.LoadFrom(@"C:\Users\mrgre\Downloads\win-x64\Nefarius.ViGEm.Client.dll");
        var clientType = asm.GetType("Nefarius.ViGEm.Client.ViGEmClient", true);
        var client = Activator.CreateInstance(clientType);
        var create = clientType.GetMethod("CreateXbox360Controller", Type.EmptyTypes);
        var pad = create.Invoke(client, null);
        var padType = pad.GetType();
        padType.GetMethod("Connect", Type.EmptyTypes).Invoke(pad, null);
        Thread.Sleep(100);
        var buttonType = asm.GetType("Nefarius.ViGEm.Client.Targets.Xbox360.Xbox360Button", true);
        var a = buttonType.GetField("A", BindingFlags.Public | BindingFlags.Static).GetValue(null);
        var set = padType.GetMethod("SetButtonState", new[] { buttonType, typeof(bool) });
        set.Invoke(pad, new object[] { a, true });
        Thread.Sleep(hold);
        set.Invoke(pad, new object[] { a, false });
        Thread.Sleep(100);
        padType.GetMethod("Disconnect", Type.EmptyTypes).Invoke(pad, null);
        ((IDisposable)client).Dispose();
        Console.WriteLine("pressed A");
    }
}

