# Estructura de la Presentación (Retail Pipeline)

Este documento contiene el contenido sugerido para tus slides.
*   **Idioma de Slides**: Inglés (Estándar profesional y consistente con el repo).
*   **Notas del Orador**: Español (Para tu discurso).

---

## Slide 1: Title
**Title**: Scalable Retail Data Pipeline
**Subtitle**: Serverless Ingestion & Incremental Transformation
**Author**: Julian Waksmann
**Role**: Senior Data Engineer Candidate

> **Notas**:
> "Hola, soy Julian. Vengo a presentarles la solución para el desafío de datos de Retail. Me enfoqué en construir una arquitectura que no solo resuelva el problema de hoy, sino que escale eficientemente para mañana usando Serverless y modelos incrementales."

---

## Slide 2: The Challenge & Objective
**Context**:
*   Daily ingestion of Store & Sales data (CSV).
*   Variable volume, potential duplicates, optional headers.
*   Requirement: Generate analytical reports for management & logistics.

**Key Goals**:
*   **Scalability**: Handle growing data volume without growing costs linearly.
*   **Robustness**: Handle headers/no-headers and schema drift.
*   **Idempotency**: Re-runnable processes without data duplication.

> **Notas**:
> "El desafío principal no es solo mover archivos, es hacerlo de forma robusta. Mis objetivos fueron asegurar que el sistema soporte picos de carga, maneje archivos mal formados y garantice que si processo el mismo archivo dos veces, el resultado sea el mismo (Idempotencia)."

---

## Slide 3: Architecture Overview
**Diagram**: (Insertar `assets/architecture_diagram.png` aquí)

**Tech Stack**:
*   **Ingestion (EL)**: AWS S3 + Lambda (Python) -> Snowflake RAW.
*   **Transformation (T)**: dbt (Data Build Tool) on Snowflake.
*   **Orchestration**: Event-Driven (S3 Trigger) + Scheduled Batch (dbt).

**Why this Stack?**
*   **Serverless**: Zero idle cost. Pay only for execution time.
*   **ELT Pattern**: Load first, Transform later. Preserves raw lineage.
*   **Separate Compute/Storage**: Snowflake scales compute independently.

> **Notas**:
> "Elegí una arquitectura ELT Serverless. Lambda nos da ingestión casi en tiempo real y costo cero cuando no hay archivos. Snowflake separa cómputo de almacenamiento. dbt nos permite aplicar ingeniería de software (versiones, tests) a los datos. Es una arquitectura moderna y mantenible."

---

## Slide 4: Ingestion Strategy (The "E" & "L")
**Design Pattern**: "Schema-on-Read"
*   **No Pre-Processing**: Lambda performs minimal validation.
*   **Bulk Loading**: Uses Snowflake `COPY INTO` (Optimized for CSV).
*   **Metadata Enrichment**: RegEx extracts `Batch Date` from filename and injects it into the table.

**Handling Edge Cases**:
*   **Optional Headers**: `SKIP_HEADER = 0`. We filter headers downstream in dbt. Prevents data loss.
*   **Archiving**: Success -> Move to `history/`. Failure -> SNS Alert.

> **Notas**:
> "Para la ingestión, la clave fue 'la menor fricción posible'. Uso COPY INTO directo. Un punto interesante: configuro Snowflake para NO saltar headers. Prefiero importar una linea de 'basura' y filtrarla luego en SQL, a perder datos porque alguien olvidó el header. Es un enfoque defensivo."

---

## Slide 5: Transformation Strategy (The "T")
**Tool**: `dbt (Data Build Tool)`

**Stage Layer (Performance)**:
*   **Materialization**: `Incremental Table` (Not View).
*   **Strategy**: `UPSERT` based on Unique Keys (`store_token`, `transaction_id`).
*   **Logic**: Process only `loaded_at > max(last_run)`.
*   **Impact**: drastically reduces compute time and cost.

**Marts Layer (Analytics)**:
*   **Challenge**: Late-arriving data affects daily aggregates.
*   **Solution**: Incremental with **Lookback Window** (7 days).
*   **Result**: Self-healing reports.

> **Notas**:
> "Aquí está el corazón de la ingeniería. No usé Vistas simples porque son lentas al leer. Implementé Tablas Incrementales reales.
> Para Stage, hago UPSERT de lo nuevo.
> Para los Reportes, uso una 'Ventana de Seguridad' de 7 días. Si llega una venta atrasada de ayer, el sistema automáticamente re-calcula los totales de ayer. Esto evita la corrupción de métricas."

---

## Slide 6: Engineering Key Decisions

We prioritized a **Serverless First** approach to minimize maintenance and cost.

*   **Ingestion (Lambda)**: We chose **AWS Lambda** over heavy ETL tools because it allows for event-driven, near-instant processing of files at zero cost when idle.
*   **Transformation (ELT over ETL)**: Instead of pre-processing data with scripts (Python/Glue) outside the warehouse, we load raw data immediately into Snowflake. This maximizes **traceability** (lineage) and leverages Snowflake's superior compute power for all transformations.
*   **Deployment (Simplicity)**: We utilized standard **Bash scripts** and **CloudFormation** for this MVP to ensure the project is self-contained and easy to deploy without external complex dependencies.

**Considered Alternatives (Modern Data Stack)**:
*   **S3 Tables (Iceberg) + Athena/dbt**: Decouples storage for cost efficiency. *Decision*: Snowflake Native chosen for speed/performance.
*   **S3 Tables (Iceberg) + Athena/dbt**: Decouples storage for cost efficiency. *Decision*: Snowflake Native chosen for speed/performance.
*   **AWS Native (Glue + Step Functions)**: A robust Serverless ETL option, allowing Spark SQL execution. *Decision*: We opted for dbt to centralize transformation logic within the Warehouse (ELT pattern), but Glue is an excellent alternative for decoupled processing.

> **Notas**:
> "Mis decisiones de ingeniería se basaron en 'Simplicidad y Potencia'.
> 1. Lambda para ingestión: Rápido y barato.
> 2. ELT: Cargar primero, transformar después.
> 3. **Alternativa Considerada**: Podríamos haber usado **S3 Tables (Iceberg)** para las capas RAW/STAGE y transformarlas con **dbt + Athena**. Esto bajaría costos de almacenamiento, pero añadimos complejidad de catálogo. Para este desafío, Snowflake Nativo fue la opción ganadora por velocidad de implementación."

---

## Slide 7: Future Improvements
**Roadmap for Production**:
1.  **Orchestration (ECS/Fargate)**: Containerize dbt to run on AWS ECS. Allows enabling Event-Driven Transformations (Real-time) vs Batch.
2.  **Security**: Migrate to **AWS Secrets Manager** for credential rotation and zero-trust security.
3.  **IaC**: Migrate to **AWS CDK** for programmable infrastructure.
4.  **Governance**: Implement Masking Policies (PII) and Data Contracts.

> **Notas**:
> "Si tuviera una semana más, ¿qué haría?
> 1. Montaría dbt en **ECS (contenedores)**.
> 2. Implementaría **AWS Secrets Manager**.
> 3. Migraría a **AWS CDK** porque prefiero definir infraestructura con código real (Python/TS) en lugar de HCL/YAML."

---

## Slide 8: Thank You
**Questions?**

*   Repository: [Link to Github]
*   Documentation: `README.md`

> **Notas**:
> "Gracias por su tiempo. Estoy listo para profundizar en cualquier parte del código o explicar la lógica SQL."
