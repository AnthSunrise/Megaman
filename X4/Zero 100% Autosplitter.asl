// Made by AntharasSunrise, report any bugs on discord: antharas_sunrise
// With the help of SCWeeb1, Ch0cman, Lillybethrosenthal, EZE_O.
// Special thanks to JohnnyGo and Coltaho for their old splitters which worked as references.

state("duckstation-qt-x64-ReleaseLTCG") {}
state("duckstation-nogui-x64-ReleaseLTCG") {}
state("duckstation") {}

startup {
    settings.Add("useGameTime", true, "Autosplitter X4 - Custom Delays per Boss");
    
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

	// 1. INTRO STAGE 2 (0x0100) - Eregon
    if (current.stageID == 0x0100) {
        // Step 1: Detectar que la pelea con Eregon inició (HP cargada a 0x30)
        if (!vars.introBossActive && !vars.introDefeated && current.bossHP == 0x30 && current.playerHP > 0) {
            vars.introBossActive = true;
            vars.introDialogueCount = 0;
        }

        if (current.playerHP == 0) {
            vars.introBossActive = false;
            vars.introDefeated = false;
        }

        // Step 2: Confirmar la derrota de Eregon (HP cae a 0 tras estar activo)
        if (vars.introBossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0) {
            vars.introBossActive = false;
            vars.introDefeated = true; // Solo ahora permitimos contar los diálogos finales
        }

        // Step 3: Contar únicamente las cajas de diálogo POST-DERROTA
        if (vars.introDefeated && old.colonelDialogue == 0x0001 && current.colonelDialogue == 0x0101) {
            vars.introDialogueCount++;

            // Al terminar el segundo diálogo tras vencerlo
            if (vars.introDialogueCount == 2 && !vars.waitingForSplit) {
                vars.introDefeated = false;
                vars.waitingForSplit = true;
                vars.timerStart = Environment.TickCount;
                vars.targetDelay = 1200; // Delay post-diálogo hacia el teleport
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
            vars.targetDelay = 17930; // Web Spider Delay
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
            vars.targetDelay = 17930; // Cyber Peacock Delay
            vars.timerActive = true;
        }
    }

    // 4. MAVERICK STAGE 0x0107 - Storm Owl (Excepción Mini-jefe)
    if (current.stageID == 0x0107) {
        if (!vars.bossActive && current.bossHP == 0x30 && current.playerHP > 0) vars.bossActive = true;
        if (current.playerHP == 0) vars.bossActive = false;

        if (vars.bossActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.bossActive = false;
            vars.owlKills++;
            if (vars.owlKills == 2) {
                vars.waitingForSplit = true;
                vars.timerStart = Environment.TickCount;
                vars.targetDelay = 17930; // Storm Owl Delay
                vars.timerActive = true;
            }
        }
    } else {
        vars.owlKills = 0;
    }

	// 5. MAVERICK STAGE 0x0104 - Magma Dragoon (HP Especial)
    if (current.stageID == 0x0104) {
        // Step 1: Detectar inicio real de la pelea
        if (!vars.dragoonActive && !vars.dragoonDefeated && current.dragoonHP == 0x30 && current.playerHP > 0) {
            vars.dragoonActive = true;
        }

        if (current.playerHP == 0) {
            vars.dragoonActive = false;
            vars.dragoonDefeated = false;
        }

        // Step 2: Confirmar la derrota (HP cae de >0 a 0)
        if (vars.dragoonActive && old.dragoonHP > 0 && current.dragoonHP == 0 && current.playerHP > 0) {
            vars.dragoonActive = false;
            vars.dragoonDefeated = true;
        }

        // Step 3: Split solo cuando se cierra el diálogo POST-DERROTA
        if (vars.dragoonDefeated && old.colonelDialogue == 0x0001 && current.colonelDialogue == 0x0101 && !vars.waitingForSplit) {
            vars.dragoonDefeated = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 2800; // Delay post-diálogo para thumbs up/teleport
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
            vars.targetDelay = 17930; // Jet Stingray Delay
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
            vars.targetDelay = 17930; // Split Mushroom Delay
            vars.timerActive = true;
        }
    }

    // 8. MAVERICK STAGE 0x0108 - Slash Beast (Multidirección Dinámica)
    if (current.stageID == 0x0108) {
        // Se activa si cualquiera de los slots registra HP llena (0x30)
        if (!vars.slashBeastActive && 
           (current.slashHP1 == 0x30 || current.slashHP2 == 0x30 || current.slashHP3 == 0x30) && 
            current.playerHP > 0) {
            vars.slashBeastActive = true;
        }

        if (current.playerHP == 0) vars.slashBeastActive = false;

        // Verifica si la HP bajó a 0 en el slot que estaba activo
        bool killedSlot1 = (old.slashHP1 > 0 && current.slashHP1 == 0);
        bool killedSlot2 = (old.slashHP2 > 0 && current.slashHP2 == 0);
        bool killedSlot3 = (old.slashHP3 > 0 && current.slashHP3 == 0);

        if (vars.slashBeastActive && (killedSlot1 || killedSlot2 || killedSlot3) && current.playerHP > 0 && !vars.waitingForSplit) {
            vars.slashBeastActive = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 17930; // Slash Beast Delay
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
            vars.targetDelay = 17930; // Frost Walrus Delay
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
                vars.targetDelay = 10200; // Colonel Delay
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
            vars.targetDelay = 11000; // Iris Delay
            vars.timerActive = true;
        }
    }

	// 12. WEAPON 1.5 (0x010B) - General
    if (current.stageID == 0x010B) {
        // Step 1: Detectar inicio real de la batalla (Vida en 0x30 tras el dialogo inicial)
        if (!vars.generalActive && !vars.generalDefeated && current.playerX > 3200 && current.bossHP == 0x30 && current.playerHP > 0) {
            vars.generalActive = true;
        }

        if (current.playerHP == 0) {
            vars.generalActive = false;
            vars.generalDefeated = false;
        }

        // Step 2: Registrar la muerte (HP cae a 0 tras estar activo)
        if (vars.generalActive && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0) {
            vars.generalActive = false;
            vars.generalDefeated = true; // Habilita la escucha del dialogo de muerte
        }

        // Step 3: Split solo tras terminar el dialogo POST-PELEA
        if (vars.generalDefeated && old.colonelDialogue == 0x0001 && current.colonelDialogue == 0x0101 && !vars.waitingForSplit) {
            vars.generalDefeated = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 200; // Delay post-diálogo hacia el teleport/fade out
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
            vars.targetDelay = 4100; // Teleport Boss Rush Delay
            vars.timerActive = true;
        }
    } else {
        vars.bossRushKills = 0;
        vars.bossRushSplitDone = false;
    }

    // 14. SIGMA STAGE (0x010C) - Split Final por Coordenada X
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

isLoading {
    if(settings["useGameTime"]) return true;
}

shutdown {
    timer.OnReset -= vars.resetAction;
}