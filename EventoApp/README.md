# Evento · app iOS (SwiftUI, iOS 17)

## Abrir en el simulador
Requisitos: macOS con Xcode 16 o posterior y Homebrew.

```bash
./scripts/run.sh
```
Genera el proyecto con XcodeGen, compila, instala y abre la app en el primer iPhone disponible del simulador.
Para abrirlo en Xcode: `xcodegen generate && open EventoApp.xcodeproj`.

Pruebas: `xcodebuild test -project EventoApp.xcodeproj -scheme EventoApp -destination 'platform=iOS Simulator,name=iPhone 16'`

## Qué probar
- **Inicio**: la agenda de ejemplo es hoy y mañana (27–28 oct 2026, hora de Quito). Con el reloj de la barra
  superior puedes simular cualquier hora del evento para ver «Ahora» y «A continuación».
- **Agenda**: Lista / Agenda (cuadrícula por sala), filtros combinables con chips, búsqueda por título o expositor.
- **Favoritos y recordatorios**: el permiso se pide al marcar el primer favorito. Marca una charla que empiece
  dentro de 10–15 minutos con antelación de 5 min para ver llegar el aviso; tócalo y abre el detalle.
- **Enlace profundo**: `xcrun simctl openurl booted evento://charla/d1-r1-1`
- La charla `d2-r3-3` viene cancelada para ver ese estado.

Para regenerar la agenda con otras fechas: `python3 scripts/generate_agenda.py 2026-11-18`.

## Estructura
- `App/` arranque, entorno, navegación por pestañas y enlaces profundos.
- `Model/` tipos del evento, lógica de horarios pura, filtros, formatos en zona horaria del evento, SwiftData.
- `Data/` EventStore, SyncService (ETag, reemplazo atómico), FavoritesStore, ReminderService, caché de imágenes, EventKit.
- `Features/` Inicio, Agenda, Expositores, Favoritos y Detalle de charla.

## Cambios respecto al plan
- SwiftData guarda la agenda como una instantánea JSON validada (más favoritos como entidad), en lugar de
  cinco entidades relacionadas. El contenido se reemplaza en bloque igualmente y evita fallos de relaciones
  de SwiftData; las vistas trabajan con structs indexados en memoria.
- Un solo target con carpetas Model/Data/Features en vez de paquetes Swift separados.
- Modo de lenguaje Swift 5 con concurrencia mínima; pasar a Swift 6 estricto es un paso aparte.
- Sin sincronización iCloud (requiere equipo de desarrollo y entitlements) ni widget (fase 5 opcional).
- `AppConfig.agendaURL` es `nil`: falta decidir el origen del contenido (backend propio, Odoo Eventos…).
