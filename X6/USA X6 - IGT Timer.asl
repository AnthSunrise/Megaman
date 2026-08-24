// Made by AntharasSunrise, report any bugs on discord: antharas_sunrise
// With the help of SCWeeb1, Ch0cman, Lillybethrosenthal, EZE_O.
// Special thanks to JohnnyGo and Coltaho for their old splitters which worked as references.

state("duckstation-qt-x64-ReleaseLTCG") {}
state("duckstation-nogui-x64-ReleaseLTCG") {}
state("duckstation") {}

startup {
    settings.Add("useGameTime", true, "IGT Timer (Megaman X6 USA)");
    
    LiveSplit.Model.Input.EventHandlerT<LiveSplit.Model.TimerPhase> resetAction = (s,e) => {
        vars.firstPass = true;
    };
    vars.resetAction = resetAction;
    timer.OnReset += vars.resetAction;
}

init {
    vars.ramBase = IntPtr.Zero;
    vars.firstPass = true;
}

update {
    if (vars.ramBase == IntPtr.Zero) {
        foreach (var page in game.MemoryPages(true)) {
            if ((int)page.RegionSize == 0x200000 || (int)page.RegionSize == 0x800000) {
                vars.ramBase = page.BaseAddress;
                break;
            }
        }
        if (vars.ramBase == IntPtr.Zero) return false;
    }

    current.igtRaw = game.ReadValue<uint>((IntPtr)vars.ramBase + 0x000ccf60);
}

isLoading {
    if(settings["useGameTime"]) return true;
}

gameTime {
    if(settings["useGameTime"]) {
        if(vars.firstPass) {
            vars.firstPass = false;
            return TimeSpan.FromMilliseconds(0);
        }

        if (current.igtRaw != null) {
            return TimeSpan.FromMilliseconds((1000.0 / 60.0) * Convert.ToDouble(current.igtRaw));
        }
    }
}

shutdown {
    timer.OnReset -= vars.resetAction;
}