# Terraform AWS – Infraestructura Modular

Proyecto de Infraestructura como Código (IaC) con Terraform en AWS, diseñado con arquitectura modular, y backend remoto. La instancia EC2 opera en modo **bastion** o **servidor web**, según la variable `bastion_enable`, ademas de worflows con GitHub Actions para el plan y apply de los servicios de AWS con OIDC.

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

## Arquitectura del Pipeline
Se diseño un worflows con dos jobs uno para plan y otro para apply
```
plan --> apply
```
## Como corre el pipeline

El pipeline corre cuando se abre un pull request apuntando a main desde cualquier rama y cuando se ahcen cambios en infra/**
Se le otorga permisos de escritura a id-token y a pull-request, de lectura a contents
Corre en dos jobs:
 - terraform-plan: Establece directorio de trabajo infra, copiamos el codigo del repo, configuramos credciales OIDC, usamos la version que se encuentra en el archivo .terraform-version, hacemos terraform check, terraform init, terraform validate y al final el plan
 - terraform-apply: Si plan pasa correctamente este job requeire aprobacion para que los cambios se apliquen

El archivo .tfvars se copio y paso a los jobs mediante una variable y se leyo con heredoc para el correcto funcionamiento del workflow.
Se añadio comentario automatico del plan en pull-request.
Se añadio las branches protection rules: status check de forma obligatorio y up to date before merging.
Se añadio environment "production" que sirve para que el job de apply requeira aprobacion antes de correr.

##OIDC y roles IAM

Se configuro OIDC para la coenxion entre GitHub Actions y AWS, se creo dos roles, github-actions-terraform-plan y github-actions-terraform-apply con politicas de permisos sigueindo la buena practoca de least privilege

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

La diferenciacion de ambientes se haran mediante carpetas y no con el uso de workspaces debido a la propensa confusion de ambientes al aplicarlos asi como codigo duplicado y demas erroes posibles.
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

- **DynamoDB para el locking del state:** el parámetro `dynamodb_table` del backend S3 está deprecado a favor de `use_lockfile`, la alternativa más reciente que no requiere una tabla DynamoDB aparte. Se optó por use_lockfile.
- **Workspaces en carpetas en vez de por ambiente:** En un entorno de producción real se recomenda separar por carpetas.
- **Servidor web en subnet pública:** no está detrás de un Load Balancer, porque ese componente no forma parte del alcance de esta iteración del proyecto.

### Próximos pasos planeados

- Base de datos (RDS) + bucket S3 para backups, con el IAM Role correspondiente.
- Restricción más granular del tráfico de salida (egress) en los Security Groups.
- Usar Pike(cloudstree) para las polciticas de permisos minimas para los roles.

## Cómo desplegar

```bash
# 1. Crear el backend remoto (bucket S3)
cd bootstrap
terraform init
terraform apply

# 2. Desplegar la infraestructura
cd ../infra
terraform init
terraform validate
terraform plan
terraform apply
```
## Troubleshooting

### Formato sub de OIDC

**Sintoma:** Not authorized to perform sts:AssumeRoleWithWebIdentity
**Causa:**
 - (a) repos creados después de julio 2026 usan un formato nuevo con IDs numéricos (repo:owner@ID/repo@ID:...)
 - (b) un job que usa environment: cambia el sub a formato environment:NOMBRE en vez de ref:refs/heads/....
**Solución:** Se uso CloudTrail, buscando AssumeRoleWithWebIdentity en us-east-1 y se ajusto la trust policy.

### Lock corrupto de DynamoDB(se cambio por use_lockfile)
**Síntoma:** unexpected end of JSON input al hacer plan/force-unlock.
**Causa:** Run colgado (por falta de -input=false) fue cancelado a mitad de camino, dejando un lock a medio escribir.
**Solución:** borrar manualmente el item de la tabla DynamoDB (o vía aws dynamodb delete-item).
