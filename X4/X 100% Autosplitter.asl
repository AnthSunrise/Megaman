// Made by AntharasSunrise, report any bugs on discord: antharas_sunrise
// With the help of SCWeeb1, Ch0cman, Lillybethrosenthal, EZE_O.
// Special thanks to JohnnyGo and Coltaho for their old splitters which worked as references.

state("duckstation-qt-x64-ReleaseLTCG") {}
state("duckstation-nogui-x64-ReleaseLTCG") {}
state("duckstation") {}

startup {
    settings.Add("useGameTime", true, "Autosplitter Mega Man X4 - X 100%");
    
    LiveSplit.Model.Input.EventHandlerT<LiveSplit.Model.TimerPhase> resetAction = (s,e) => {
        vars.bossRushKills = 0;
        vars.owlKills = 0;
        vars.bossActive = false;
        vars.introBossActive = false;
        vars.introDefeated = false;
        vars.introDialogueCount = 0;
        vars.dragoonActive = false;
        vars.dragoonDefeated = false;
        vars.dragoonSplitDone = false;
        vars.colonel1Active = false;
        vars.colonel1Defeated = false;
        vars.slashBeastActive = false;
        vars.colonelActive = false;
        vars.doubleActive = false;
        vars.doubleDefeated = false;
        vars.generalActive = false;
        vars.generalDefeated = false;
        vars.finalSplitDone = false;
        vars.bossRushSplitDone = false;
        vars.timerActive = false;
        vars.waitingForSplit = false;
    };
    vars.resetAction = resetAction;
    timer.OnReset += vars.resetAction;
}

init {
    vars.ramBase = IntPtr.Zero;
    vars.bossRushKills = 0;
    vars.owlKills = 0;
    vars.bossActive = false;
    vars.introBossActive = false;
    vars.introDefeated = false;
    vars.introDialogueCount = 0;
    vars.dragoonActive = false;
    vars.dragoonDefeated = false;
    vars.dragoonSplitDone = false;
    vars.colonel1Active = false;
    vars.colonel1Defeated = false;
    vars.slashBeastActive = false;
    vars.colonelActive = false;
    vars.doubleActive = false;
    vars.doubleDefeated = false;
    vars.generalActive = false;
    vars.generalDefeated = false;
    vars.finalSplitDone = false;
    vars.bossRushSplitDone = false;
    vars.timerActive = false;
    vars.waitingForSplit = false;
    vars.targetDelay = 0;
    vars.timerStart = 0;
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

    // HP en slots dinámicos para Slash Beast
    current.slashHP1 = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013C064);
    current.slashHP2 = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013BF2C);
    current.slashHP3 = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013BFC8);

    // HP de Double (comparte dirección con la gema de Iris)
    current.doubleHP = game.ReadValue<byte>((IntPtr)vars.ramBase + 0x0013bfc8);
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
        vars.introDefeated = false;
        vars.introDialogueCount = 0;
        vars.dragoonActive = false;
        vars.dragoonDefeated = false;
        vars.dragoonSplitDone = false;
        vars.colonel1Active = false;
        vars.colonel1Defeated = false;
        vars.slashBeastActive = false;
        vars.colonelActive = false;
        vars.doubleActive = false;
        vars.doubleDefeated = false;
        vars.generalActive = false;
        vars.generalDefeated = false;
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
            vars.targetDelay = 17570; // Delay ajustado para X
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
            vars.targetDelay = 17570; // Delay ajustado para X
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
                vars.targetDelay = 17570; // Delay ajustado para X
                vars.timerActive = true;
            }
        }
    } else {
        vars.owlKills = 0;
    }

    // 5. MAVERICK STAGE 0x0104 - Magma Dragoon (Derrota Base & Revisit)
    if (current.stageID == 0x0104) {
        // CASO A: PELEA PRINCIPAL
        if (!vars.dragoonSplitDone) {
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
                vars.dragoonSplitDone = true; // Sella el split de la primera visita
                vars.waitingForSplit = true;
                vars.timerStart = Environment.TickCount;
                vars.targetDelay = 2800;
                vars.timerActive = true;
            }
        }
        // CASO B: REVISIT (Pieza de la Fourth Armor)
        else {
            // Si el split de Dragoon ya se hizo y la coordenada X cae a 0x0000 por el Escape
            if (old.playerX > 0 && current.playerX == 0) {
                return true;
            }
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
            vars.targetDelay = 17570; // Delay ajustado para X
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
            vars.targetDelay = 17570; // Delay ajustado para X
            vars.timerActive = true;
        }
    }

    // 8. MAVERICK STAGE 0x0108 - Slash Beast (Multidirección Dinámica)
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
            vars.targetDelay = 17570; // Delay ajustado para X
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
            vars.targetDelay = 17570; // Delay ajustado para X
            vars.timerActive = true;
        }
    }

    // 10. INTERMEDIATE STAGE (0x0009) - Colonel 1
    if (current.stageID == 0x0009) {
        if (!vars.colonel1Active && !vars.colonel1Defeated && current.bossHP == 0x30 && current.playerHP > 0) {
            vars.colonel1Active = true;
        }

        if (current.playerHP == 0) {
            vars.colonel1Active = false;
            vars.colonel1Defeated = false;
        }

        if (vars.colonel1Active && old.bossHP > 0 && current.bossHP == 0 && current.playerHP > 0) {
            vars.colonel1Active = false;
            vars.colonel1Defeated = true;
        }

        if (vars.colonel1Defeated && old.colonelDialogue == 0x0001 && current.colonelDialogue == 0x0101 && !vars.waitingForSplit) {
            vars.colonel1Defeated = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 1260; // Delay de diálogo a teleport
            vars.timerActive = true;
        }
    } else {
        vars.colonel1Active = false;
        vars.colonel1Defeated = false;
    }

    // 11. SPACEPORT (0x000A) - Colonel 2
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

    // 12. WEAPON 1 (0x000B) - Double
    if (current.stageID == 0x000B) {
        if (!vars.doubleActive && !vars.doubleDefeated && current.doubleHP == 0x30 && current.playerHP > 0) {
            vars.doubleActive = true;
        }

        if (current.playerHP == 0) {
            vars.doubleActive = false;
            vars.doubleDefeated = false;
        }

        if (vars.doubleActive && old.doubleHP > 0 && current.doubleHP == 0 && current.playerHP > 0) {
            vars.doubleActive = false;
            vars.doubleDefeated = true;
        }

        if (vars.doubleDefeated && old.colonelDialogue == 0x0001 && current.colonelDialogue == 0x0101 && !vars.waitingForSplit) {
            vars.doubleDefeated = false;
            vars.waitingForSplit = true;
            vars.timerStart = Environment.TickCount;
            vars.targetDelay = 8490;
            vars.timerActive = true;
        }
    } else {
        vars.doubleActive = false;
        vars.doubleDefeated = false;
    }

    // 13. WEAPON 1.5 (0x010B) - General
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

    // 14. BOSS RUSH (0x000C)
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

    // 15. SIGMA STAGE (0x010C) - Split Final por Coordenada X
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