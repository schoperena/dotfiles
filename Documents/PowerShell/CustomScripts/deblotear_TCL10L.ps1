# Script de debloat — TCL 10L Gen4
# Estrategia: intenta uninstall, si falla usa disable
# PowerShell — ejecutar: .\debloat.ps1
# Si da error de permisos primero correr:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

Write-Host "Verificando dispositivo..." -ForegroundColor Cyan
adb devices
Write-Host ""
Write-Host "Procesando 24 paquetes..." -ForegroundColor Yellow
$ok = 0; $fail = 0

Write-Host "  -> android.autoinstalls.config.TCL.PAI" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 android.autoinstalls.config.TCL.PAI 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 android.autoinstalls.config.TCL.PAI 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.android.bluetoothmidiservice" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.android.bluetoothmidiservice 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.android.bluetoothmidiservice 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.android.calllogbackup" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.android.calllogbackup 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.android.calllogbackup 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.android.egg" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.android.egg 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.android.egg 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.android.email.partnerprovider" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.android.email.partnerprovider 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.android.email.partnerprovider 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.android.providers.partnerbookmarks" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.android.providers.partnerbookmarks 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.android.providers.partnerbookmarks 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.android.traceur" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.android.traceur 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.android.traceur 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.facebook.appmanager" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.facebook.appmanager 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.facebook.appmanager 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.facebook.services" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.facebook.services 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.facebook.services 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.facebook.system" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.facebook.system 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.facebook.system 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.apps.books" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.apps.books 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.apps.books 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.apps.chromecast.app" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.apps.chromecast.app 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.apps.chromecast.app 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.apps.tachyon" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.apps.tachyon 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.apps.tachyon 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.apps.youtube.kids" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.apps.youtube.kids 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.apps.youtube.kids 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.feedback" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.feedback 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.feedback 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.gm" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.gm 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.gm 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.gms.location.history" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.gms.location.history 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.gms.location.history 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.keep" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.keep 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.keep 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.marvin.talkback" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.marvin.talkback 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.marvin.talkback 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.printservice.recommendation" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.printservice.recommendation 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.printservice.recommendation 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.google.android.tag" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.google.android.tag 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.google.android.tag 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.mediatek.atmwifimeta" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.mediatek.atmwifimeta 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.mediatek.atmwifimeta 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.mediatek.engineermode" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.mediatek.engineermode 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.mediatek.engineermode 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host "  -> com.mediatek.mdmconfig" -ForegroundColor Gray
$result = adb shell pm uninstall -k --user 0 com.mediatek.mdmconfig 2>&1
if ($result -match "Success") {
    Write-Host "     OK (uninstalled)" -ForegroundColor Green
    $ok++
} else {
    $result2 = adb shell pm disable-user --user 0 com.mediatek.mdmconfig 2>&1
    if ($result2 -match "disabled") {
        Write-Host "     OK (disabled)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "     FALLO: $result2" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host "Resultado: $ok OK, $fail fallaron" -ForegroundColor Cyan
Write-Host "Reinicia la tablet para aplicar cambios." -ForegroundColor Green