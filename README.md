# Terraform AWS – Infraestructura Modular

Proyecto de Infraestructura como Código (IaC) con Terraform en AWS, diseñado con arquitectura modular, múltiples ambientes (workspaces) y backend remoto. La instancia EC2 opera en modo **bastion** o **servidor web**, según la variable `bastion_enable`.

## Pre-requisitos

- Terraform v1.15.6
- AWS CLI v2.36.2
- Cuenta de AWS con credenciales configuradas

## Arquitectura

```
VPC (172.16.0.0/16)
│
├── Subnet pública 1a ── NAT Gateway + EIP
├── Subnet pública 1b ── (EC2: bastion o servidor web)
└── Subnet privada 1a
```

- La **VPC** contiene 3 subnets: dos públicas y una privada.
- El **Internet Gateway (IGW)** está asociado a la VPC y da salida/entrada a las subnets públicas.
- El **NAT Gateway** vive en una subnet pública, asociado a una route table que tiene salida a internet a través del IGW.
- La **subnet privada** está asociada a una route table que enruta su tráfico de salida a través del NAT Gateway — las instancias que se creen ahí tienen acceso a internet sin ser alcanzables desde afuera.
- La **instancia EC2** (bastion o servidor web, según `bastion_enable`) se crea en una subnet pública en ambos casos, ya que el proyecto no incluye un Load Balancer en esta iteración.

## Módulos

| Módulo | Responsabilidad |
|---|---|
| `networking` | Crea la VPC, subnets, NAT Gateway e IGW para que el resto de los módulos los consuman. |
| `security` | Crea el Security Group para la instancia de `compute`. |
| `compute` | Crea la instancia EC2. |
| `iam` | Crea el IAM Role y el Instance Profile. |
| `monitoring` | Crea las herramientas de monitoreo (CloudWatch + SNS). |

## Backend remoto

El backend remoto se gestiona desde una carpeta `bootstrap/`, separada del resto de la infraestructura (`infra/`), porque ahí se crean los dos recursos que el backend remoto necesita: el bucket S3 y la tabla DynamoDB para el almacenamiento del `tfstate`.

Esta separación existe para evitar el problema del huevo y la gallina: para almacenar el `tfstate` de `infra` en un bucket remoto, ese bucket tiene que existir *antes* — no puede ser creado por el mismo proyecto que depende de él.

## Ambientes

Se crean los ambientes con:

```bash
terraform workspace new dev
terraform workspace new prod
```

Y se cambia de ambiente con:

```bash
terraform workspace select dev
```

Para este proyecto, la diferencia entre ambos ambientes se limita a tags y nombres — no se profundizó más porque la recomendación general es separar ambientes con carpetas en vez de workspaces, debido a problemas conocidos al trabajar con workspaces (confusión sobre en qué ambiente se está parado, mayor propensión a errores al compartir el mismo código entre ambientes, entre otros).

## Estimación de costos

Estimación generada con [Infracost](https://www.infracost.io/).

**Proyecto `bootstrap`:** $0.00/mes (S3 y DynamoDB solo cobran por uso real; sin uso, no generan costo base).

**Proyecto `infra`:** ~$48.93/mes

| Recurso | Costo mensual |
|---|---|
| NAT Gateway (730 hs) | $32.85 |
| EC2 t3.small (730 hs) | $15.18 |
| Volumen EBS (8 GB, gp2) | $0.80 |
| Alarma de CloudWatch | $0.10 |
| SNS | Según uso |

**El mayor costo es el NAT Gateway**, que cobra tanto por hora activo como por GB de datos procesados.

## Decisiones y limitaciones conocidas

- **DynamoDB para el locking del state:** el parámetro `dynamodb_table` del backend S3 está deprecado a favor de `use_lockfile`, la alternativa más reciente que no requiere una tabla DynamoDB aparte. Se optó por DynamoDB de todas formas por su valor de aprendizaje y porque sigue siendo el patrón más extendido en proyectos reales existentes.
- **Workspaces en vez de carpetas por ambiente:** se eligieron workspaces por motivos estrictamente académicos, sabiendo que en un entorno de producción real se recomendaría separar por carpetas.
- **Servidor web en subnet pública:** no está detrás de un Load Balancer, porque ese componente no forma parte del alcance de esta iteración del proyecto.

### Próximos pasos planeados

- Base de datos (RDS) + bucket S3 para backups, con el IAM Role correspondiente.
- Restricción más granular del tráfico de salida (egress) en los Security Groups.

## Cómo desplegar

```bash
# 1. Crear el backend remoto (bucket S3 + tabla DynamoDB)
cd bootstrap
terraform init
terraform apply

# 2. Desplegar la infraestructura
cd ../infra
terraform init
terraform workspace select dev   # o prod, o dejar default
terraform plan
terraform apply
```
