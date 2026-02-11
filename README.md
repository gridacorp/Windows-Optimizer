![Windows 11](https://img.shields.io/badge/Windows-11-blue?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)
![Category](https://img.shields.io/badge/Category-Optimization-orange)


<img width="765" height="576" alt="image" src="https://github.com/user-attachments/assets/6549d4aa-5e49-457a-b0e0-2cbc18dccc18" />

### ⚙️ Funcionalidades principales de Ultimate Windows Optimizer v4.0

1. **Creación automática de punto de restauración + respaldo completo del registro:** Genera punto de restauración del sistema y exporta las 5 colmenas del registro (HKCR, HKCU, HKLM, HKU, HKCC) al Escritorio antes de cualquier modificación; esencial para revertir cambios en equipos de oficina con recursos limitados o flujos de trabajo críticos de diseño/renderizado.

2. **Gestión RAM adaptativa según hardware (<8GB vs ≥8GB):** Detecta automáticamente la memoria total y aplica optimizaciones diferenciadas: para sistemas con <8GB desactiva servicios pesados (SysMain, WSearch) para liberar recursos en equipos de oficina; para ≥8GB activa optimizaciones de latencia (`DisablePagingExecutive=1`) que benefician renderizado 3D y diseño gráfico al mantener el kernel en RAM.

3. **Detección automática SSD/HDD y optimización específica:** Identifica el tipo de almacenamiento mediante PowerShell y aplica TRIM para SSDs (prolongando vida útil en equipos de diseño con cargas intensivas de lectura/escritura) o defragmentación optimizada para HDDs en equipos de oficina antiguos.

4. **Desactivación profunda de Windows Defender (nivel kernel):** Deshabilita servicios y drivers críticos (`WdFilters`, `WdBoot`, `WdNisDrv`), elimina carpetas del sistema mediante `takeown/icacls` y bloquea reinstalación; **requiere antivirus alternativo previo** – especialmente útil en estaciones de renderizado donde los escaneos en tiempo real ralentizan procesos intensivos.

5. **Eliminación inteligente de bloatware con detección OEM automática:** Quita 30+ apps Microsoft preinstaladas y detecta/aplica filtros para apps de fabricantes (HP, Lenovo, Dell, ASUS, Acer) excluyendo drivers críticos; ideal para equipos de oficina con software OEM innecesario que consume recursos limitados.

6. **Configuración del plan de energía "Ultimate Performance":** Habilita el plan oculto de Windows (`e9a42b02-d5df-448d-aa00-03f14749eb61`) + Game Mode activado; mantiene CPU/GPU en estado de máxima disponibilidad sin throttling, crucial para renderizado 3D continuo y flujos de trabajo de diseño gráfico exigentes.

7. **Desactivación completa de indexación y búsqueda:** Detiene y deshabilita permanentemente el servicio `WSearch`, eliminando actividad constante en disco; beneficia especialmente SSDs en equipos de diseño al reducir escrituras innecesarias y prolongar vida útil del almacenamiento.

8. **Ajustes avanzados de GPU para aceleración profesional:** Habilita escalado de GPU (`EnableGPUScaling=1`) y programación por hardware (`HwSchMode=2`); mejora el rendimiento en aplicaciones de diseño (Adobe Suite, Blender) y renderizado aprovechando al máximo la GPU dedicada.

9. **Optimización de arranque mediante bcdedit:** Ajusta parámetros del gestor de arranque (`numproc`, `useplatformclock=false`, `disabledynamictick=yes`) para reducir tiempos de inicio; especialmente útil en equipos de oficina con arranques frecuentes durante jornada laboral.

10. **Desactivación de efectos visuales y Fluent Design:** Elimina transparencias (`EnableTransparency=0`), animaciones (`MinAnimate=0`) y aplica tema visual ligero; reduce carga en GPU/CPU en equipos de oficina con recursos limitados (4-8GB RAM, gráficos integrados), mejorando fluidez en Office y navegación.

11. **Bloqueo total de telemetría y recolección de datos:** Configura `AllowTelemetry=0`, detiene servicios de diagnóstico (DiagTrack, dmwappushservice) y revoca permisos de hardware; aumenta privacidad en entornos corporativos y libera recursos de CPU/RAM para tareas productivas.

12. **Configuración de actualizaciones en modo manual/bloqueado:** Detiene `wuauserv`, configura inicio manual y bloquea conexiones a servidores de Windows Update (`DoNotConnectToWindowsUpdateInternetLocations=1`); evita reinicios inesperados durante renders largos o jornadas críticas en oficina.

13. **Desactivación de BitLocker:** Inicia proceso de descifrado con `manage-bde -off C:` para eliminar sobrecarga de cifrado en disco; **advertencia:** mejora rendimiento en lecturas/escrituras intensivas (renderizado, diseño), pero solo recomendable en equipos sin datos sensibles.

14. **Optimización avanzada de red (TCP/IP):** Habilita RSS (Receive Side Scaling), configura algoritmo de congestión CUBIC y desactiva IPv6; reduce latencias en transferencias de archivos grandes (proyectos de diseño, assets 3D) y mejora estabilidad en conexiones corporativas.

15. **Limpieza inteligente de WinSxS:** Ejecuta análisis previo (`DISM /AnalyzeComponentStore`) seguido de limpieza segura del almacenamiento de componentes; libera espacio crítico en equipos de oficina con SSDs pequeños (<256GB) sin comprometer integridad del sistema.

16. **Forzado de hibernación como modo predeterminado:** Activa hibernación (`powercfg /hibernate on`) y desactiva completamente la suspensión; ideal para equipos de diseño/renderizado que requieren reanudar sesiones largas sin perder trabajo en curso.

17. **Desactivación total de Storage Sense:** Bloquea limpiezas automáticas mediante políticas (`DisableStorageSense=1`); previene eliminación accidental de archivos temporales de diseño/renderizado durante procesos en ejecución.

18. **Instalación automática de software esencial productivo:** Instala Brave Browser (privacidad), VLC (reproducción multimedia), WinRAR (compresión) y Nomacs (visor de imágenes ligero); optimiza equipos de oficina con software mínimo pero funcional sin bloatware innecesario.

19. **Eliminación completa de Widgets y Xbox:** Desactiva Widgets desde registro y políticas, desinstala Windows Web Experience Pack y elimina todos los componentes de Xbox; libera RAM/CPU en equipos de oficina con recursos limitados destinados exclusivamente a productividad.

20. **Ajuste de prioridad de CPU para aplicaciones críticas:** Configura `Win32PrioritySeparation=38` y asigna prioridad alta a procesos como `explorer`, `chrome`; mejora respuesta en interfaces de diseño (Photoshop, Illustrator) y reduce micro-estancamientos durante renderizado.

21. **Desactivación de OneDrive y sincronización en la nube:** Termina procesos, desactiva servicios y bloquea sincronización mediante políticas; elimina consumo constante de ancho de banda y CPU en equipos de oficina con conexiones limitadas o proyectos locales sensibles.

22. **Optimización específica para equipos de bajos recursos (<8GB RAM):** Aplica desactivación extrema de efectos visuales, servicios no esenciales (SysMain, WSearch) y limita apps en segundo plano; transforma equipos antiguos en estaciones de oficina funcionales para Word, Excel y navegación ligera.

23. **Optimización específica para renderizado y diseño (≥8GB RAM):** Activa caché del sistema ampliado (`LargeSystemCache=1`), desactiva paginación del kernel y optimiza latencia de CPU/GPU; maximiza throughput en Blender, Maya, Adobe Creative Suite y flujos de trabajo 3D intensivos.

24. **Limpieza profunda de inicio automático:** Elimina entradas en `Run` (usuario y sistema) y carpetas de Startup; reduce tiempo de arranque en equipos de oficina y libera RAM al inicio para aplicaciones productivas inmediatas.

25. **Deshabilitación de Game DVR y Game Bar:** Desactiva captura de pantalla/video en segundo plano; previene caídas de FPS y uso de recursos durante sesiones de diseño gráfico donde se requiere máxima estabilidad de la GPU.
---
### 🧩 Uso

1. Ejecuta el script como administrador para que todos los cambios se apliquen correctamente.
2. Se recomienda crear un punto de restauración del sistema antes de usarlo.
3. Lee y comprende cada cambio, ya que algunos pueden afectar funcionalidades del sistema.

---
> [!CAUTION]
> **Acciones Críticas:** Este script desactiva **BitLocker** (descifrado de disco) y **Windows Defender** (Antivirus). Asegúrate de entender las implicaciones de seguridad antes de proceder.

### ⚠️ Descargo de responsabilidad
Este script se proporciona “tal cual”, sin garantías de ningún tipo.
Su uso es responsabilidad exclusiva del usuario que lo ejecuta o lo distribuye.
No nos hacemos responsables por posibles efectos no deseados, pérdida de funcionalidades o daños derivados de su aplicación.
Recomendado solo para usuarios avanzados con pleno conocimiento de las modificaciones que se aplican.
---

Si necesitas ayuda o deseas contribuir, abre un issue o un pull request.
