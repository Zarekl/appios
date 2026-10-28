"""Genera EventoApp/Resources/agenda.json con datos de ejemplo (hoy y mañana, hora de Quito)."""
import json, datetime as dt, urllib.parse, sys

DAYS = [dt.date(2026, 10, 27), dt.date(2026, 10, 28)]
if len(sys.argv) > 1:
    d0 = dt.date.fromisoformat(sys.argv[1]); DAYS = [d0, d0 + dt.timedelta(days=1)]
UTC_OFFSET = 5  # America/Guayaquil = UTC-5, sin horario de verano

rooms = [
    {"id": "r1", "name": "Auditorio Principal", "floor": "Planta baja", "capacity": 600},
    {"id": "r2", "name": "Sala Chimborazo", "floor": "Piso 1", "capacity": 180},
    {"id": "r3", "name": "Sala Cotopaxi", "floor": "Piso 1", "capacity": 120},
    {"id": "r4", "name": "Taller Pichincha", "floor": "Piso 2", "capacity": 40},
]
tracks = [
    {"id": "dev", "name": "Desarrollo", "color": "#2563EB"},
    {"id": "prod", "name": "Producto", "color": "#9333EA"},
    {"id": "data", "name": "Datos e IA", "color": "#059669"},
    {"id": "biz", "name": "Negocio", "color": "#D97706"},
]
people = [
    ("Ana Lucía Paredes", "Arquitecta de software", "Andina Labs"),
    ("Diego Salazar", "CTO", "Nube Austral"),
    ("Gabriela Andrade", "Líder de producto", "Cóndor Fintech"),
    ("Mateo Villacís", "Ingeniero de datos", "Datos del Pacífico"),
    ("Valeria Cevallos", "Diseñadora UX", "Volcán Studio"),
    ("Andrés Moncayo", "Consultor ERP", "Mitad del Mundo Ventures"),
    ("Camila Espinosa", "Científica de datos", "Andina Labs"),
    ("Javier Ortega", "Desarrollador iOS", "Volcán Studio"),
    ("Sofía Benítez", "Directora de operaciones", "Cóndor Fintech"),
    ("Tomás Zambrano", "Ingeniero de plataforma", "Nube Austral"),
    ("Isabel Proaño", "Investigadora en IA", "Universidad Central"),
    ("Ricardo Jaramillo", "Fundador", "Ruta Logística"),
    ("Paula Guerrero", "Product manager", "Datos del Pacífico"),
    ("Esteban Flores", "Especialista en seguridad", "Nube Austral"),
]
speakers = []
for i, (name, role, company) in enumerate(people, 1):
    seed = urllib.parse.quote(name)
    speakers.append({
        "id": f"sp{i}", "name": name, "role": role, "company": company,
        "bio": f"{name.split()[0]} trabaja como {role.lower()} en {company}. Lleva más de diez años construyendo productos digitales en la región y colabora con comunidades técnicas de Quito y Guayaquil.",
        "photoURL": f"https://api.dicebear.com/9.x/notionists/png?seed={seed}&size=256&backgroundColor=e0e7ff,d1fae5,fef3c7",
        "links": [{"label": "Sitio web", "url": f"https://example.com/{seed.lower()}"}],
    })

titles = [
    ("Apertura: el software que mueve a la región", "biz", "Keynote"),
    ("Módulos a medida sin romper las actualizaciones", "dev", "Charla"),
    ("Facturación electrónica en Ecuador, paso a paso", "biz", "Charla"),
    ("Del pedido al despacho: inventario en tiempo real", "prod", "Charla"),
    ("Modelos de lenguaje para soporte al cliente", "data", "Charla"),
    ("Informes QWeb que no dan miedo", "dev", "Taller"),
    ("Cómo priorizar un roadmap con pocos recursos", "prod", "Charla"),
    ("Panel: transformación digital en pymes", "biz", "Panel"),
    ("Pruebas automáticas en proyectos de ERP", "dev", "Charla"),
    ("Tableros de ventas que la gerencia sí lee", "data", "Charla"),
    ("Diseñar formularios para personas reales", "prod", "Charla"),
    ("Integraciones con APIs bancarias", "dev", "Charla"),
    ("Migraciones de versión sin perder datos", "dev", "Taller"),
    ("Pronóstico de demanda con datos históricos", "data", "Charla"),
    ("Precios y márgenes en el comercio electrónico", "biz", "Charla"),
    ("Accesibilidad en apps móviles", "prod", "Charla"),
    ("Seguridad de accesos y permisos en un ERP", "dev", "Charla"),
    ("Automatizar la conciliación bancaria", "biz", "Taller"),
    ("Clasificar documentos con visión por computadora", "data", "Charla"),
    ("Entrevistas a usuarios en una semana", "prod", "Charla"),
    ("Escalar PostgreSQL cuando crece la empresa", "dev", "Charla"),
    ("Panel: talento técnico en Ecuador", "biz", "Panel"),
    ("Keynote: lo que aprendimos en diez años de implementaciones", "biz", "Keynote"),
    ("Arquitectura de microservicios, ¿cuándo sí?", "dev", "Charla"),
    ("Métricas de producto que importan", "prod", "Charla"),
    ("Asistentes de IA dentro del ERP", "data", "Charla"),
    ("Taller de SwiftUI para apps de negocio", "dev", "Taller"),
    ("Contabilidad multiempresa sin dolores de cabeza", "biz", "Charla"),
    ("Experimentos A/B con muestras pequeñas", "data", "Charla"),
    ("Onboarding que reduce el abandono", "prod", "Charla"),
    ("Observabilidad para equipos pequeños", "dev", "Charla"),
    ("Taller de modelado de datos para analistas", "data", "Taller"),
    ("Punto de venta sin conexión", "prod", "Charla"),
    ("Cumplimiento tributario automatizado", "biz", "Charla"),
    ("Despliegues continuos con poco riesgo", "dev", "Charla"),
    ("Taller de prompts para equipos de negocio", "data", "Taller"),
    ("Logística de última milla en ciudades andinas", "biz", "Charla"),
    ("Sistemas de diseño en equipos pequeños", "prod", "Charla"),
    ("Rendimiento de consultas en el ORM", "dev", "Charla"),
    ("Panel: datos abiertos y gobierno", "data", "Panel"),
    ("Gestión de proyectos ágil en implementaciones", "prod", "Charla"),
    ("Recursos humanos y nómina en la nube", "biz", "Charla"),
    ("Taller de integración con WhatsApp", "dev", "Taller"),
    ("Cierre: hacia dónde va el software empresarial", "biz", "Keynote"),
]
slots = {
    "r1": [(9, 0, 60), (10, 15, 45), (11, 15, 75), (14, 0, 60), (15, 15, 60), (16, 30, 60)],
    "r2": [(9, 30, 45), (10, 30, 60), (11, 45, 45), (14, 0, 45), (15, 0, 60), (16, 15, 45)],
    "r3": [(9, 30, 60), (10, 45, 60), (12, 0, 30), (14, 30, 60), (15, 45, 45), (16, 45, 45)],
    "r4": [(9, 0, 90), (11, 0, 90), (14, 0, 120), (16, 15, 90)],
}
levels = ["Básico", "Intermedio", "Avanzado"]

def iso(day, h, m):
    t = dt.datetime(day.year, day.month, day.day, h, m) + dt.timedelta(hours=UTC_OFFSET)
    return t.strftime("%Y-%m-%dT%H:%M:%SZ")

# Reparte títulos: talleres a la sala de talleres, keynotes al auditorio.
workshops = [t for t in titles if t[2] == "Taller"]
keynotes = [t for t in titles if t[2] == "Keynote"]
others = [t for t in titles if t[2] not in ("Taller", "Keynote")]
sessions, n = [], 0
for di, day in enumerate(DAYS, 1):
    for room in rooms:
        for si, (h, m, dur) in enumerate(slots[room["id"]], 1):
            if room["id"] == "r4" and workshops:
                title, track, fmt = workshops.pop(0)
            elif room["id"] == "r1" and ((di == 1 and si == 1) or (di == 2 and si == len(slots["r1"]))) and keynotes:
                title, track, fmt = keynotes.pop(0) if di == 1 else keynotes.pop()
            else:
                title, track, fmt = others.pop(0) if others else (keynotes.pop(0) if keynotes else workshops.pop(0))
            end_min = h * 60 + m + dur
            sp = [f"sp{(n % len(people)) + 1}"] + ([f"sp{((n + 5) % len(people)) + 1}"] if fmt == "Panel" else [])
            sid = f"d{di}-{room['id']}-{si}"
            sessions.append({
                "id": sid, "title": title,
                "abstract": f"Una sesión práctica sobre {title[0].lower() + title[1:]}. Veremos casos reales, errores frecuentes y qué hacer el lunes siguiente.",
                "start": iso(day, h, m), "end": iso(day, end_min // 60, end_min % 60),
                "roomId": room["id"], "trackId": track, "speakerIds": sp,
                "format": fmt, "level": levels[n % 3], "language": "Inglés" if n % 7 == 3 else "Español",
                "updatedAt": "2026-10-20T15:00:00Z",
                **({"cancelled": True} if sid == "d2-r3-3" else {}),
            })
            n += 1

agenda = {
    "version": "2026-10-20.1",
    "event": {"name": "Encuentro Tech Quito 2026", "venue": "Centro de Convenciones, Quito", "timeZone": "America/Guayaquil"},
    "rooms": rooms, "tracks": tracks, "speakers": speakers, "sessions": sessions,
}
out = "EventoApp/Resources/agenda.json"
with open(out, "w", encoding="utf-8") as f:
    json.dump(agenda, f, ensure_ascii=False, indent=2)
print(f"{len(sessions)} charlas, {len(speakers)} expositores → {out}")
