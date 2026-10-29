# Batería (edición original)

Esta carpeta conserva la primera edición del widget como referencia. Su ID de
Plasma es `org.kde.fir3.batterydisplay-original`; no es la edición principal
actual. Para instalaciones nuevas, usa [Battery](../org.kde.fir3.batterydisplay-firstversion/README.md)
o [Battery (testing)](../org.kde.fir3.batterydisplay-testing/README.md).

## Qué incluye

- Porcentaje y nivel de batería en el panel.
- Colores configurables para los niveles de aviso y crítico.
- Animación sencilla de barrido y pulso al cargar.
- Vista previa opcional con porcentaje y estado de carga simulados.
- Datos reales de `BatteryControlModel` cuando la vista previa está apagada.

Esta versión no incluye el catálogo de 25 animaciones de las ediciones
actuales. Tampoco incluye `install.sh`; se conserva aquí como código fuente
histórico.

## Archivos

```text
metadata.json
contents/
├── config/
│   ├── config.qml
│   └── main.xml
└── ui/
    ├── BatteryVisual.qml
    ├── configGeneral.qml
    └── main.qml
```

Consulta el README de la edición principal o testing para instrucciones de
instalación y uso actualizadas.
