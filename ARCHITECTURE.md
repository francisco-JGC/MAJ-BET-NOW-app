# Arquitectura — MajbetNow App (Flutter)

Este documento describe la arquitectura del proyecto **majbetnow-app**, la aplicación móvil construida con **Flutter + Dart** para el sistema MajbetNow.

## Contexto del monorepo

El sistema completo se compone de tres proyectos independientes:

| Proyecto | Rol | Stack |
|---|---|---|
| `majbetnow-backend` | API / servicios de dominio | NestJS + TypeORM + PostgreSQL |
| `majbetnow-app` | App móvil para vendedores/impresión | Flutter + Dart |
| `majbetnow-web` | Panel admin | React + Vite |

Este documento cubre **únicamente** `majbetnow-app`.

## Estrategia: Feature-First + Clean Architecture

Organizamos el código **por funcionalidad de negocio** (feature), no por capa técnica. Cada feature es un módulo autocontenido con sus tres capas de Clean Architecture (`domain`, `data`, `presentation`).

**Ventajas:**
- Cada feature se puede desarrollar, probar y refactorizar de forma aislada.
- Onboarding rápido: para trabajar en "impresora", todo lo relevante vive en `features/printer/`.
- Escala mejor que la estructura layer-first cuando el número de features crece.
- Facilita eliminar o migrar features completas.

## Estructura de directorios

```
lib/
│
├── core/                          # Código compartido entre features
│   ├── errors/                    # Excepciones y failures del dominio
│   ├── theme/                     # ThemeData, colores, tipografía
│   ├── network/                   # Cliente HTTP, interceptors
│   ├── utils/                     # Helpers genéricos
│   └── di/                        # Inyección de dependencias (get_it, etc.)
│
├── features/                      # Módulos de negocio
│   │
│   ├── printer/                   # Módulo: Impresora (Bluetooth / térmica)
│   │   ├── domain/
│   │   │   ├── entities/          # Modelos puros (Ticket, PrinterDevice…)
│   │   │   ├── repositories/      # Interfaces abstractas
│   │   │   └── usecases/          # print_ticket.dart, connect_printer.dart
│   │   │
│   │   ├── data/
│   │   │   ├── datasources/       # printer_bluetooth_datasource.dart
│   │   │   ├── models/            # DTOs con fromJson/toJson
│   │   │   └── repositories/      # printer_repository_impl.dart
│   │   │
│   │   └── presentation/
│   │       ├── state/             # printer_cubit.dart / printer_notifier.dart
│   │       ├── screens/           # printer_setup_page.dart
│   │       └── widgets/           # Widgets específicos de la feature
│   │
│   └── sales/                     # Módulo: Ventas / Carrito
│       ├── domain/
│       ├── data/
│       └── presentation/
│
└── main.dart                      # Entry point + configuración global
```

## Capas por feature

### `domain/` — reglas de negocio puras
- **entities/**: objetos de negocio inmutables. Sin dependencias de Flutter ni de librerías externas.
- **repositories/**: **interfaces abstractas**. El dominio declara *qué* necesita, no *cómo* se implementa.
- **usecases/**: una clase por acción de negocio (`PrintTicket`, `ConnectPrinter`). Recibe repositorios por constructor.

**Regla:** `domain/` no importa nada de `data/` ni de `presentation/`.

### `data/` — implementación de acceso a datos
- **datasources/**: acceso crudo (Bluetooth, HTTP, SQLite, SharedPreferences…). Uno por tecnología.
- **models/**: DTOs que extienden/mapean a entidades. Contienen `fromJson`/`toJson`.
- **repositories/**: implementaciones concretas de las interfaces de `domain/`.

**Regla:** `data/` puede importar `domain/`, nunca al revés.

### `presentation/` — UI y estado
- **state/**: gestión de estado (Bloc / Cubit / Riverpod). Consume `usecases`, nunca repositorios ni datasources directamente.
- **screens/**: páginas completas.
- **widgets/**: componentes reutilizables dentro de la feature.

**Regla:** `presentation/` importa `domain/` (para tipos y usecases). No importa `data/`.

## Flujo de dependencias

```
presentation  ──▶  domain  ◀──  data
      │              ▲            │
      │              │            │
      └──────────────┴────────────┘
                     ▲
                  (usecases)
```

Las flechas apuntan hacia `domain`. El dominio no depende de nadie; todos dependen de él.

## Convenciones

- **Nombres de archivo:** `snake_case.dart`.
- **Nombres de clase:** `PascalCase`.
- **Una clase pública por archivo** (salvo widgets pequeños asociados).
- **Sufijos consistentes:**
  - Entidades: `Ticket`, `PrinterDevice` (sin sufijo).
  - Modelos DTO: `TicketModel`, `PrinterDeviceModel`.
  - Repos abstractos: `PrinterRepository`.
  - Repos concretos: `PrinterRepositoryImpl`.
  - Usecases: verbo en imperativo — `PrintTicket`, `ConnectPrinter`.
  - Estado: `PrinterCubit` / `PrinterState` o `PrinterNotifier`.
- **Carpeta `core/`** solo para código realmente **compartido entre 2+ features**. Si algo lo usa una sola feature, vive dentro de esa feature.

## Stack técnico

| Categoría | Paquete | Rol |
|---|---|---|
| **State management** | `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` | Estado reactivo de UI y usecases |
| **DI (infra)** | `get_it` | Registrar servicios de infraestructura (Dio, prefs, repos) |
| **HTTP** | `dio` | Cliente HTTP con interceptors |
| **Errores** | `fpdart` | `Either<Failure, T>` en repos/usecases |
| **Modelos inmutables** | `freezed` + `freezed_annotation` | `copyWith`, `==`, `hashCode` autogenerados |
| **JSON** | `json_annotation` + `json_serializable` | `fromJson`/`toJson` autogenerados |
| **Value equality (simple)** | `equatable` | Failures y clases sin freezed |
| **Routing** | `go_router` | Navegación declarativa |
| **i18n / formato** | `intl` | Fechas, monedas, pluralización |
| **Logging** | `logger` | Logs estructurados |
| **Env vars** | `flutter_dotenv` | Carga `.env` como asset |
| **Storage KV** | `shared_preferences` | Preferencias locales simples |
| **Code gen runner** | `build_runner` | `dart run build_runner build` |
| **Tests** | `mocktail` | Mocks sin code gen |

## Gestión de estado — Riverpod

**Elección:** `flutter_riverpod` con `riverpod_annotation` + `riverpod_generator`.

Motivo: menos boilerplate que Bloc, buen manejo de estado async (que domina la app: HTTP + Bluetooth + UI), compile-time safety vía generación de código.

- **Providers** viven en `features/<feature>/presentation/state/`.
- Un provider por unidad de estado. Ejemplo:
  ```dart
  @riverpod
  class PrinterController extends _$PrinterController {
    @override
    PrinterState build() => const PrinterState.disconnected();

    Future<void> connect(String deviceId) async { ... }
  }
  ```
- El estado se modela con `freezed` (unions/sealed classes) para representar `loading | success | error` explícitamente.
- Los usecases se resuelven desde `get_it` dentro del provider (no se inyectan como providers de Riverpod).

## Inyección de dependencias — get_it + Riverpod

**División de responsabilidades:**

- **`get_it`** (`core/di/injection.dart`): registra la infraestructura y las dependencias del dominio.
  - Singletons: `Logger`, `SharedPreferences`, `DioClient`.
  - Lazy singletons: repositorios concretos, datasources.
  - Factories: usecases.
- **Riverpod**: gestiona el **estado de UI**. Los controllers/notifiers resuelven usecases desde `get_it`.

Ejemplo de registro (`core/di/injection.dart`):
```dart
getIt.registerLazySingleton<PrinterRepository>(
  () => PrinterRepositoryImpl(datasource: getIt()),
);
getIt.registerFactory(() => PrintTicket(repository: getIt()));
```

Uso desde un provider:
```dart
@riverpod
class PrinterController extends _$PrinterController {
  late final _printTicket = getIt<PrintTicket>();
  ...
}
```

## Code generation

Freezed, json_serializable y riverpod_generator usan `build_runner`. Comandos:

```bash
# Generación única (después de añadir/editar anotaciones):
dart run build_runner build --delete-conflicting-outputs

# Watch continuo (recomendado en desarrollo):
dart run build_runner watch --delete-conflicting-outputs
```

Los archivos generados (`*.g.dart`, `*.freezed.dart`) están excluidos del analyzer en `analysis_options.yaml`.

## Errores — `fpdart` + `Either`

Los repositorios devuelven `Either<Failure, T>` en lugar de lanzar excepciones. El dominio no conoce excepciones — solo `Failure`s (definidos en `core/errors/failures.dart`: `ServerFailure`, `NetworkFailure`, `CacheFailure`, `ValidationFailure`, `UnexpectedFailure`).

Los datasources sí lanzan `Exception`s (`core/errors/exceptions.dart`). Es responsabilidad del repositorio capturarlas y mapearlas a `Failure`s.

```dart
Future<Either<Failure, Ticket>> print(TicketPayload p) async {
  try {
    final ticket = await datasource.print(p);
    return Right(ticket);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  }
}
```

## Configuración de entorno

- **`.env.example`** (en git): documenta las variables esperadas.
- **`.env`** (fuera de git): valores reales locales. Se carga como asset vía `flutter_dotenv`.
- El asset `.env` está declarado en `pubspec.yaml → flutter → assets`.
- La carga en `main.dart` es tolerante a errores (si no existe, la app arranca igual).

## Testing

Cada feature debe tener su carpeta espejo en `test/features/<feature>/`:

```
test/
└── features/
    └── printer/
        ├── domain/usecases/print_ticket_test.dart
        ├── data/repositories/printer_repository_impl_test.dart
        └── presentation/state/printer_cubit_test.dart
```

- **Domain**: tests unitarios puros (sin mocks de Flutter).
- **Data**: tests con datasources mockeados (`mocktail`).
- **Presentation**: tests de estado + widget tests para pantallas críticas.

## Añadir una nueva feature — checklist

1. Crear `lib/features/<nombre>/` con las subcarpetas `domain/`, `data/`, `presentation/`.
2. Definir entidades y repositorios (interfaces) en `domain/`.
3. Escribir usecases y sus tests unitarios.
4. Implementar datasources, models y repositorio concreto en `data/`.
5. Registrar el repositorio en `core/di/`.
6. Construir UI en `presentation/` consumiendo usecases vía estado.
7. Añadir carpeta espejo en `test/features/<nombre>/`.
