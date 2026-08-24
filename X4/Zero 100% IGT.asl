// Made by AntharasSunrise, discord: antharas_sunrise
// This is not a script for a main leaderboard, this is more of a silly test script in an attempt to make X4 run through in-game time, only counting the time you have control of Zero just like X5 and X6 works.

state("duckstation-qt-x64-ReleaseLTCG") {}
state("duckstation-nogui-x64-ReleaseLTCG") {}
state("duckstation") {}

startup {
    settings.Add("useGameTime", true, "Autosplitter X4 - Zero 100%");
    settings.Add("enableIGT", true, "IGT Mode - Only count the time you have control of zero.", "useGameTime");
    
    LiveSplit.Model.Input.EventHandlerT<LiveSplit.Model.TimerPhase> resetAction = (s,e) => {
        vars.bossRushKills = 0;
        vars.owlKills = 0;
        vars.bossActive = false;
        vars.introBossActive = false;
        vars.dragoonActive = false;
        vars.slashBeastActive = false;
        vars.colonelActive = false;
        vars.irisActive = false;
        vars.generalActive = false;
        vars.finalSplitDone = false;
        vars.bossRushSplitDone = false;
        vars.timerActive = false;
        vars.generalActive = false;
        vars.generalDefeated = false;
        vars.waitingForSplit = false;
    };
    vars.resetAction = resetAction;
    timer.OnReset += vars.resetAction;
}

init {
    vars.ramBase = IntPtr.Zero;
    vars.bossRushKills = 0;
    vars.introBossActive = false;
    vars.introDefeated = false;
    vars.dragoonActive = false;
    vars.dragoonDefeated = false;
    vars.owlKills = 0;
    vars.bossActive = false;
    vars.introBossActive = false;
    vars.dragoonActive = false;
    vars.slashBeastActive = false;
    vars.colonelActive = false;
    vars.irisActive = false;
    vars.generalActive = false;
    vars.finalSplitDone = false;
    vars.bossRushSplitDone = false;
    vars.timerActive = false;
    vars.waitingForSplit = false;
    vars.targetDelay = 0;
    vars.timerStart = 0;
    vars.generalActive = false;
    vars.generalDefeated = false;
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

    current.stageID = game.ReadValue<ushort>((IntPtr)vars.ramBase + 0x001721cc);
    current.playerHP = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x00141924);
    current.bossHP = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013BF2C);
    
    // Lectura del estado de control del personaje (ushort en 0x001721dc)
    current.controlState = game.ReadValue<ushort>((IntPtr)vars.ramBase + 0x001721dc);

    // HP específica de Magma Dragoon
    current.dragoonHP = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013C19C);

    // HP en slots dinámicos posibles para Slash Beast
    current.slashHP1 = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013C064);
    current.slashHP2 = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013BF2C);
    current.slashHP3 = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013BFC8);

    current.irisCrystalHP = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013bfc8);
    current.playerX = game.ReadValue<ushort>((IntPtr)vars.ramBase + 0x0013e47a);

    current.colonelDialogue = game.ReadValue<ushort>((IntPtr)vars.ramBase + 0x001721de);
    current.bossRushEvent = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x001721dc);

    // Selección de personaje
    current.selectConfirm = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x001721e6);
	
	// Pausar el timer al estar en el menu de pausa
	current.isPaused = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x001721C1);
}

start {
    if (current.stageID == 0x010E && old.selectConfirm != 0x01 && current.selectConfirm == 0x01) {
        vars.bossRushKills = 0;
        vars.owlKills = 0;
        vars.bossActive = false;
        vars.introBossActive = false;
        vars.dragoonActive = false;
        vars.slashBeastActive = false;
        vars.colonelActive = false;
        vars.irisActive = false;
        vars.introBossActive = false;
        vars.introDefeated = false;
        vars.dragoonActive = false;
        vars.dragoonDefeated = false;
        vars.generalActive = false;
        vars.finalSplitDone = false;
        vars.bossRushSplitDone = false;
        vars.timerActive = false;
        vars.waitingForSplit = false;

        // Pausamos inmediatamente el Game Time e iniciamos en 0
        timer.IsGameTimePaused = true;
        timer.SetGameTime(TimeSpan.Zero);
        return true;
    }
}

reset {
    if (old.stageID != 0x010E && current.stageID == 0x010E) {
        return true;
    }
}

split {
    // --- MANEJO CENTRALIZADO DEL TIMER DE DELAY ---
    if (vars.timerActive) {
        if (Environment.TickCount - vars.timerStart >= vars.targetDelay) {
            vars.timerActive = false;
            vars.waitingForSplit = false;
            return true;
        }
        return false;
    }

    // 1. INTRO STAGE 2 (0x0100) - Eregion
    if (current.stageID == 0x0100) {
        if (!vars.introBossActive && !vars.introDefeated && current.bossHP == 0x30 && current.playerHP > 0) {
            vars.introBossActive = true;
            vars.introDialogueCount = 0;
        }

        if (current.playerHP == 0) {
            vars.introBossActive = false;
            vars.introDefeated = false;
        }

        if (vars.introBossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0) {
            vars.introBossActive = false;
            vars.introDefeated = true;
        }

        if (vars.introDefeated && old.colonelDialogue == 0x0001 && current.colonelDialogue == 0x0101) {
            vars.introDialogueCount++;

            if (vars.introDialogueCount == 2 && !vars.waitingForSplit) {
                vars.introDefeated = false;
                vars.waitingForSplit = true;
                vars.timerStart = Environment.TickCount;
                vars.targetDelay = 1200;
                vars.timerActive = true;
            }
        }
    } else {
        vars.introBossActive = false;
        vars.introDefeated = false;
        vars.introDialogueCount = 0;
    }

    // 2. MAVERICK STAGE 0x0101 - Web Spider
    if (current.stageID == 0x0101) {
        if (!vars.bossActive && current.bossHP == 0x30 && current.playerHP > 0) vars.bossActive = true;
        if (current.playerHP == 0) vars.bossActive = false;

        if (vars.bossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.bossActive = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 17930;
            vars.timerActive = true;
        }
    }

    // 3. MAVERICK STAGE 0x0106 - Cyber Peacock
    if (current.stageID == 0x0106) {
        if (!vars.bossActive && current.bossHP == 0x30 && current.playerHP > 0) vars.bossActive = true;
        if (current.playerHP == 0) vars.bossActive = false;

        if (vars.bossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.bossActive = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 17930;
            vars.timerActive = true;
        }
    }

    // 4. MAVERICK STAGE 0x0107 - Storm Owl
    if (current.stageID == 0x0107) {
        if (!vars.bossActive && current.bossHP == 0x30 && current.playerHP > 0) vars.bossActive = true;
        if (current.playerHP == 0) vars.bossActive = false;

        if (vars.bossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.bossActive = false;
            vars.owlKills++;
            if (vars.owlKills == 2) {
                vars.waitingForSplit = true;
                vars.timerStart = Environment.TickCount;
                vars.targetDelay = 17930;
                vars.timerActive = true;
            }
        }
    } else {
        vars.owlKills = 0;
    }

    // 5. MAVERICK STAGE 0x0104 - Magma Dragoon
    if (current.stageID == 0x0104) {
        if (!vars.dragoonActive && !vars.dragoonDefeated && current.dragoonHP == 0x30 && current.playerHP > 0) {
            vars.dragoonActive = true;
        }

        if (current.playerHP == 0) {
            vars.dragoonActive = false;
            vars.dragoonDefeated = false;
        }

        if (vars.dragoonActive && old.dragoonHP > 0 && current.dragoonHP == 0 && current.playerHP > 0) {
            vars.dragoonActive = false;
            vars.dragoonDefeated = true;
        }

        if (vars.dragoonDefeated && old.colonelDialogue == 0x0001 && current.colonelDialogue == 0x0101 && !vars.waitingForSplit) {
            vars.dragoonDefeated = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 2800;
            vars.timerActive = true;
        }
    } else {
        vars.dragoonActive = false;
        vars.dragoonDefeated = false;
    }

    // 6. MAVERICK STAGE 0x0105 - Jet Stingray
    if (current.stageID == 0x0105) {
        if (!vars.bossActive && current.bossHP == 0x30 && current.playerHP > 0) vars.bossActive = true;
        if (current.playerHP == 0) vars.bossActive = false;

        if (vars.bossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.bossActive = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 17930;
            vars.timerActive = true;
        }
    }

    // 7. MAVERICK STAGE 0x0103 - Split Mushroom
    if (current.stageID == 0x0103) {
        if (!vars.bossActive && current.bossHP == 0x30 && current.playerHP > 0) vars.bossActive = true;
        if (current.playerHP == 0) vars.bossActive = false;

        if (vars.bossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.bossActive = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 17930;
            vars.timerActive = true;
        }
    }

    // 8. MAVERICK STAGE 0x0108 - Slash Beast
    if (current.stageID == 0x0108) {
        if (!vars.slashBeastActive && 
           (current.slashHP1 == 0x30 || current.slashHP2 == 0x30 || current.slashHP3 == 0x30) && 
            current.playerHP > 0) {
            vars.slashBeastActive = true;
        }

        if (current.playerHP == 0) vars.slashBeastActive = false;

        bool killedSlot1 = (old.slashHP1 > 0 && current.slashHP1 == 0);
        bool killedSlot2 = (old.slashHP2 > 0 && current.slashHP2 == 0);
        bool killedSlot3 = (old.slashHP3 > 0 && current.slashHP3 == 0);

        if (vars.slashBeastActive && (killedSlot1 || killedSlot2 || killedSlot3) && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.slashBeastActive = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 17930;
            vars.timerActive = true;
        }
    } else {
        vars.slashBeastActive = false;
    }

    // 9. MAVERICK STAGE 0x0102 - Frost Walrus
    if (current.stageID == 0x0102) {
        if (!vars.bossActive && current.bossHP == 0x30 && current.playerHP > 0) vars.bossActive = true;
        if (current.playerHP == 0) vars.bossActive = false;

        if (vars.bossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.bossActive = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 17930;
            vars.timerActive = true;
        }
    }

    // 10. SPACEPORT (0x000A) - Colonel
    if (current.stageID == 0x000A) {
        if (!vars.colonelActive && current.bossHP == 0x30 && current.playerHP > 0) vars.colonelActive = true;
        if (current.playerHP == 0) vars.colonelActive = false;

        if (vars.colonelActive && current.bossHP == 0 && current.playerHP > 0 && !vars.waitingForSplit) {
            if (old.colonelDialogue == 0x0001 && current.colonelDialogue == 0x0101) {
                vars.colonelActive = false;
                vars.waitingForSplit = true;
                vars.timerStart = Environment.TickCount;
                vars.targetDelay = 10200;
                vars.timerActive = true;
            }
        }
    }

    // 11. WEAPON 1 (0x000B) - Iris
    if (current.stageID == 0x000B) {
        if (!vars.irisActive && current.irisCrystalHP == 0x30 && current.playerHP > 0) vars.irisActive = true;
        if (current.playerHP == 0) vars.irisActive = false;

        if (vars.irisActive && old.irisCrystalHP > 0 && current.irisCrystalHP == 0 && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.irisActive = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 11000;
            vars.timerActive = true;
        }
    }

    // 12. WEAPON 1.5 (0x010B) - General
    if (current.stageID == 0x010B) {
        if (!vars.generalActive && !vars.generalDefeated && current.playerX > 3200 && current.bossHP == 0x30 && current.playerHP > 0) {
            vars.generalActive = true;
        }

        if (current.playerHP == 0) {
            vars.generalActive = false;
            vars.generalDefeated = false;
        }

        if (vars.generalActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0) {
            vars.generalActive = false;
            vars.generalDefeated = true;
        }

        if (vars.generalDefeated && old.colonelDialogue == 0x0001 && current.colonelDialogue == 0x0101 && !vars.waitingForSplit) {
            vars.generalDefeated = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 200;
            vars.timerActive = true;
        }
    } else {
        vars.generalActive = false;
        vars.generalDefeated = false;
    }

    // 13. BOSS RUSH (0x000C)
    if (current.stageID == 0x000C) {
        if (!vars.bossActive && current.bossHP == 0x30 && current.playerHP > 0) vars.bossActive = true;
        if (current.playerHP == 0) vars.bossActive = false;

        if (vars.bossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0) {
            vars.bossActive = false;
            vars.bossRushKills++;
        }

        if (vars.bossRushKills >= 8 && current.playerX == 1864 && current.bossRushEvent == 0x01 && !vars.waitingForSplit && !vars.bossRushSplitDone) {
            vars.bossRushSplitDone = true;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 4100;
            vars.timerActive = true;
        }
    } else {
        vars.bossRushKills = 0;
        vars.bossRushSplitDone = false;
    }

    // 14. SIGMA STAGE (0x010C)
    if (current.stageID == 0x010C) {
        if (!vars.finalSplitDone) {
            if (old.playerX <= 0x06E0 && current.playerX > 0x06E0) {
                vars.finalSplitDone = true;
                return true;
            }
        }
    } else {
        vars.finalSplitDone = false;
    }
}

isLoading
{
    if (settings["enableIGT"]) {
        // 1. Pausa si el menú del juego está abierto (0x02 en 0x001721C1)
        if (current.isPaused == 0x02) {
            return true;
        }

        // 2. Pausa obligatoria en menú de selección (0x010E) y stage select/transición (0x000D)
        if (current.stageID == 0x010E || current.stageID == 0x000D) {
            return true;
        }

        // 3. Pausa durante la pantalla negra del Intro Stage hasta que Zero aparece (X > 8)
        if (current.stageID == 0x0000 && current.playerX <= 0x0008) {
            return true;
        }

        // 4. Pausa normal cuando se pierde el control en el resto del juego
        return (current.controlState & 0xFF) == 1;
    }
}

shutdown {
    timer.OnReset -= vars.resetAction;
}
