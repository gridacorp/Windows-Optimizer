# Ultimate Windows Optimizer v5.0

![Windows 11](https://img.shields.io/badge/Windows-11-blue?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)
![Category](https://img.shields.io/badge/Category-Optimization-orange)
![Version](https://img.shields.io/badge/Version-5.0-red)

<img width="765" height="576" alt="image" src="https://github.com/user-attachments/assets/6549d4aa-5e49-457a-b0e0-2cbc18dccc18" />

> Optimización automática con detección inteligente de hardware (RAM + tipo de disco).

---

## ✨ Novedades v5.0

| Tipo | Cambio |
|------|--------|
| 🔧 **Fix crítico** | LogonUI crash: eliminación de CBS reemplazada por desactivación vía registro |
| 🔧 **Fix energía** | Planes de energía: lógica unificada con `Ultimate Performance` + fallback |
| 🎯 **Modo HDD+≤4GB** | Optimización agresiva: pagefile fijo, prefetch OFF, 15+ servicios desactivados |
| 🎯 **Modo SSD+≤4GB** | Optimización equilibrada: prefetch ON, TRIM activo, efectos visuales suaves |
| ⚡ **Rendimiento** | DNS Cloudflare, TCP optimizado, limpieza inteligente de memoria |

---

## ⚙️ Funcionalidades

### 🔐 Seguridad
- Punto de restauración + backup completo del registro (5 colmenas)
- Defender desactivable (nivel kernel) ⚠️ *requiere antivirus alternativo*
- BitLocker desactivable ⚠️ *solo equipos sin datos sensibles*

### 🧠 Memoria y Almacenamiento
```
Detección automática → Optimización específica:
├─ RAM <5GB + HDD  → Modo Extremo (agresivo)
├─ RAM <5GB + SSD  → Modo SSD-LowRAM (equilibrado)
└─ RAM ≥5GB        → Optimizaciones estándar
```
- Pagefile adaptativo por hardware
- TRIM/defrag según tipo de disco
- Limpieza WinSxS con DISM

### 🗑️ Bloatware y Privacidad
- 30+ apps Microsoft eliminadas + detección OEM (HP/Lenovo/Dell/ASUS/Acer)
- Telemetría bloqueada (`AllowTelemetry=0`)
- Widgets, Copilot, Xbox, OneDrive desactivados
- Indexación (WSearch) deshabilitada

### ⚡ Rendimiento
- Plan `Ultimate Performance` activado + Game Mode
- `Win32PrioritySeparation=38` para priorizar apps activas
- Efectos visuales minimizados (sin animaciones, transparencia OFF)
- Arranque optimizado vía `bcdedit`

### 🌐 Red y Software
- DNS: Cloudflare 1.1.1.1 + 1.0.0.1
- TCP: RSS enabled, CUBIC, IPv6 disabled
- Instalación automática: Brave, VLC, WinRAR, Nomacs (vía winget)

---

## 🧩 Uso Rápido

```cmd
1. Descargar Optimizador-Windows11-v5.0.bat
2. Clic derecho → "Ejecutar como administrador"
3. Esperar 5-15 min (según hardware)
4. Reiniciar cuando se solicite
```

**Verificación post-ejecución:**
```cmd
powercfg /getactivescheme                    :: Plan activo
powershell "Get-PhysicalDisk | ft MediaType" :: Tipo de disco
systeminfo | findstr "Memory"                :: RAM detectada
```

**Revertir cambios:**
- Restaurar desde punto de restauración creado automáticamente
- O importar backups desde `Desktop\Backup_Registro\*.reg`

---

## ⚠️ Advertencias Críticas

> [!CAUTION]
> - **Defender desactivado**: instala antivirus alternativo antes de ejecutar
> - **BitLocker desactivado**: datos sin cifrar en disco
> - **Windows Update manual**: aplica parches de seguridad periódicamente
> - **Cambios permanentes**: usa backup previo para revertir si es necesario

> [!TIP]
> Prueba primero en máquina virtual con snapshot.

---

## 🔧 Solución de Problemas

| Problema | Solución |
|----------|----------|
| LogonUI crash | Restaurar carpeta `MicrosoftWindows.Client.CBS` + `sfc /scannow` |
| Brave no predeterminado | Configurar manualmente en `Settings → Apps → Default apps` |
| Cambios no aplican | Reiniciar equipo; verificar ejecución como Admin |
| winget falla | Actualizar: `winget upgrade --id Microsoft.WinGet` |
| Acceso denegado | Ejecutar como Administrador (UAC) |

---

## 📄 Licencia y Contribución

```
MIT License • Sin garantías • Uso bajo responsabilidad del usuario
```

**Contribuir:**
1. Fork → rama `feature/mejora` → PR con descripción y pruebas
2. Reportar resultados: hardware, Windows version, métricas antes/después

**Issue rápido:**
```markdown
- [ ] CPU/GPU/RAM/Disco
- [ ] Windows 11 build
- [ ] Problema o mejora propuesta
```

---

> ⭐ Útil? Dale estrella al repo.  
> 🔄 Comparte tus resultados.  
> 🛡️ Usa responsablemente, siempre con backup.

```
Desarrollado para la comunidad de optimización Windows.
```
