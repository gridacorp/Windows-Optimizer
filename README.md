![Windows 11](https://img.shields.io/badge/Windows-11-blue?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)
![Category](https://img.shields.io/badge/Category-Optimization-orange)



## Optimizador de Windows 11 - Optimización Integral
Este script en batch está diseñado para realizar una optimización profunda y personalizada de Windows 11. Desactiva efectos visuales, bloquea la telemetría, elimina servicios y aplicaciones innecesarias (como Microsoft Edge y Xbox), ajusta configuraciones de red, energía y rendimiento, con el objetivo de mejorar significativamente la eficiencia del sistema.

---
### 🚀 Funcionalidades principales
1. **Creación de punto de restauración:** Permite revertir cualquier cambio si algo no funciona correctamente. Es una medida de seguridad esencial antes de modificar el sistema.
2. **Desactivación de efectos visuales y Fluent Design** (deshabilita transparencias y animaciones innecesarias): Reduce el consumo de GPU y CPU al eliminar animaciones, sombras y transparencias; mejora la fluidez general y la respuesta en equipos con recursos limitados.
3. **Bloqueo completo de telemetría** (DiagTrack, dmwappushservice, WER): Impide el envío de datos a Microsoft, aumentando la privacidad del usuario y reduciendo procesos en segundo plano que consumen recursos.
4. **Configuración del modo manual para Windows Update** (`wuauserv` en inicio manual y bloqueo de conexiones a ubicaciones de actualización de Internet): Evita descargas y reinicios inesperados; da control total sobre cuándo y cómo se aplican las actualizaciones, reduciendo uso de red y picos de CPU/Disk durante horas críticas.
5. **Optimización del arranque mediante `bcdedit`** (establece número de procesadores, `useplatformclock=false`, `disabledynamictick=yes`): Mejora tiempos de arranque y estabilidad al ajustar parámetros del gestor de arranque para un inicio más eficiente y predecible.
6. **Instalación y configuración de Brave como navegador predeterminado** (instala si no está presente y lo configura como predeterminado): Proporciona un navegador centrado en privacidad y con bloqueo de rastreadores integrado, reduciendo seguimiento y mejorando tiempos de carga en navegación.
7. **Deshabilitación de Widgets, Cortana y componentes de Xbox** (deshabilita, desinstala y bloquea servicios y tareas relacionadas): Elimina procesos y servicios que consumen memoria y CPU en segundo plano, liberando recursos para aplicaciones principales.
8. **Aplicación del plan de energía "Alto rendimiento"** (habilita y activa Ultimate Performance o Alto Rendimiento): Mantiene el procesador y hardware en estado de máxima disponibilidad, ideal para juegos y tareas exigentes que requieren respuesta instantánea.
9. **Optimización de red** (ajustes TCP/IP: habilita RSS, `congestionprovider=cubic`, desactiva IPv6): Mejora la estabilidad y rendimiento de la red, reduce latencias y puede mejorar la experiencia en juegos y transferencias de archivos.
10. **Limpieza de aplicaciones de inicio y procesos en segundo plano** (elimina entradas en `Run` y desactiva permisos de ejecución en segundo plano): Acelera el arranque del sistema y reduce el consumo sostenido de memoria y CPU durante la sesión.
11. **Desactivación de Windows Defender y servicios de protección** (protección en tiempo real, basada en la nube y SmartScreen): Reduce el uso de CPU y accesos a disco por escaneos constantes; **solo** recomendable si se dispone de un antivirus alternativo y actualizado.
12. **Ajuste automático del archivo de paginación** según la memoria RAM instalada (calcula y fija `pagefile`): Optimiza la gestión de memoria virtual para evitar ralentizaciones cuando la RAM se llena; proporciona un tamaño de paginación más adecuado al hardware.
13. **Desactivación de indexación y búsqueda** (detiene y deshabilita `WSearch`): Reduce la actividad permanente en disco, lo cual es ventajoso en SSDs para mejorar vida útil y disminuir operaciones I/O innecesarias.
14. **Habilitación del Modo de Juego y aceleración por hardware GPU** (activa Game Mode y configura `HwSchMode`): Prioriza recursos del sistema y la GPU para juegos, mejora la estabilidad y el rendimiento en títulos compatibles.
15. **Eliminación de bloatware mediante PowerShell y DISM** (quita paquetes UWP de Xbox, Store, Correo, etc.): Libera espacio en disco, reduce procesos y servicios no deseados, y simplifica el sistema para el uso real del usuario.
16. **Configuración avanzada de privacidad en el registro** (reduce recolección de datos, revoca permisos de micrófono/cámara y desactiva tareas del CEIP): Minimiza la exposición de datos personales y el comportamiento de aplicaciones que acceden a recursos sensibles, mejorando la privacidad general.
17. **Forzado de hibernación en lugar de suspensión** (activa hibernación y desactiva `standby-timeout` en AC/DC): Conserva el estado de la sesión de forma segura sin depender de la energía en modo suspensión; evita problemas al reanudar en equipos que presentan fallos con sleep.
18. **Actualización automática de software mediante `winget`** (`winget upgrade --all`): Mantiene las aplicaciones instaladas al día de forma automatizada, reduciendo vulnerabilidades por software desactualizado.
19. **Desactivación de BitLocker** si está activo en la unidad C: (verifica estado y lo desactiva): Elimina la sobrecarga de cifrado en disco que puede afectar rendimiento en lecturas/escrituras; **solo recomendable** si el cifrado no es requerido por seguridad del usuario.
20. **Deshabilitación de Game DVR y Game Bar** (ajusta claves de registro pertinentes a 0): Previene grabaciones y procesos de captura en segundo plano que provocan caídas de FPS y uso adicional de recursos durante juegos.
21. **Ajuste de escalado de GPU y prioridad de CPU** (modifica prioridades de procesos como `explorer`, `chrome` y `Win32PrioritySeparation`): Mejora la asignación de recursos hacia procesos importantes, ofreciendo mayor rendimiento en tareas críticas y reduciendo latencias en aplicaciones prioritarias.
22. **Deshabilitación de SysMain (Superfetch)** para SSDs (detiene y deshabilita el servicio; optimización condicionada por RAM): Evita actividades de prefetch que no benefician a unidades SSD modernas y reduce uso constante de RAM en equipos con alta memoria.
23. **Eliminación del límite de ancho de banda de Windows Update** (configura políticas de Delivery Optimization): Permite que las actualizaciones se descarguen sin restricciones cuando se ejecuten manualmente, acelerando el proceso de actualización.
24. **Deshabilitación de servicios innecesarios** (ej.: Fax, RemoteRegistry, OneDrive): Minimiza la superficie de ataque y reduce procesos y servicios en segundo plano que no aportan utilidad para la mayoría de usuarios.
25. **Desactivación de Storage Sense** mediante claves de registro: Evita eliminaciones y limpiezas automáticas no deseadas y previene procesos de mantenimiento que pueden consumir recursos en momentos inoportunos.


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
