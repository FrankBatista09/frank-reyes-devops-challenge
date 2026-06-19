# Terraform — Azure · IaC (bonus)

Infraestructura productiva en Azure, organizada por módulos. Provisiona toda la
plataforma sobre la que corre la app: red, registro, clúster, egress, observabilidad
y los add-ons de Kubernetes.

## Estructura

```
terraform/
├── versions.tf            # required_version + providers (azurerm, helm, kubernetes, random)
├── providers.tf           # azurerm + kubernetes/helm (configurados desde los outputs de AKS)
├── main.tf                # composición: RG + módulos + role assignment AcrPull
├── variables.tf           # variables raíz (con defaults)
├── outputs.tf             # ACR, AKS, IP de egress, workspace, comando de credenciales
├── environments/
│   └── production.tfvars  # valores del entorno productivo
└── modules/
    ├── networking/        # VNet + subnet del AKS
    ├── gateway/           # NAT Gateway (egress determinístico) + Public IP
    ├── acr/               # Azure Container Registry (admin off, solo AAD)
    ├── aks/               # AKS: Azure CNI Overlay, Calico (NetworkPolicy), autoscaler, OMS agent
    ├── monitoring/        # Log Analytics workspace + Container Insights
    └── k8s-addons/        # Helm: ingress-nginx + cert-manager
```

## Módulos

| Módulo | Recursos | Notas |
|--------|----------|-------|
| `networking` | VNet, subnet AKS | Base de red |
| `gateway` | Public IP + NAT Gateway + asociaciones | Egress determinístico (`outbound_type = userAssignedNATGateway`) |
| `acr` | Container Registry | `admin_enabled = false` (autenticación por identidad) |
| `aks` | Kubernetes cluster | CNI Overlay, `network_policy = calico` (habilita NetworkPolicy), autoscaler 2→5, OIDC/Workload Identity, OMS agent |
| `monitoring` | Log Analytics + ContainerInsights | Métricas/logs del clúster |
| `k8s-addons` | Helm `ingress-nginx`, `cert-manager` | Controlador de ingress (LoadBalancer) + emisión TLS |

El role assignment **AcrPull** (kubelet identity del AKS → ACR) se crea en `main.tf`
para que el clúster jale la imagen sin `imagePullSecrets`.

## Prerrequisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.9
- [Azure CLI](https://learn.microsoft.com/cli/azure/) autenticado: `az login`

## Uso

```bash
cd terraform
terraform init
terraform plan  -var-file=environments/production.tfvars -out tfplan
terraform apply tfplan        # capturar esta salida como evidencia
terraform output
```

> **Nota (providers de Kubernetes/Helm):** los providers `kubernetes` y `helm` se
> configuran a partir de los outputs del AKS. Si en el primer `apply` aún no existe
> el clúster, Terraform crea primero el AKS y luego aplica los add-ons en el mismo
> plan. Si tu versión de provider se queja en el primer ciclo, aplica en dos pasos:
>
> ```bash
> terraform apply -target=module.aks -var-file=environments/production.tfvars
> terraform apply -var-file=environments/production.tfvars
> ```

## Conectar y desplegar la app

```bash
$(terraform output -raw get_credentials_command)        # az aks get-credentials ...

ACR=$(terraform output -raw acr_login_server)
az acr login --name "${ACR%%.*}"
docker tag devsu-demo-devops-nodejs:local "$ACR/devsu-demo-devops-nodejs:latest"
docker push "$ACR/devsu-demo-devops-nodejs:latest"

kubectl apply -f ../k8s/addons/cluster-issuer.yaml      # TLS (cert-manager)
cd ../k8s/overlays/prod
kustomize edit set image devsu-demo-devops-nodejs="$ACR/devsu-demo-devops-nodejs:latest"
kubectl apply -k .
```

## Salida para el pipeline

`terraform output` entrega los valores que se configuran como **GitHub Actions
Variables/Secrets** para el CI/CD:

| Output | Uso en CI/CD |
|--------|--------------|
| `acr_name` | Variable `ACR_NAME` |
| `resource_group` | Variable `AKS_RESOURCE_GROUP` |
| `aks_cluster_name` | Variable `AKS_CLUSTER_NAME` |

Las credenciales de Azure (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`,
`AZURE_SUBSCRIPTION_ID`) se configuran como **Secrets** usando OIDC federado.

## Despliegue por CI/CD — workflow `Terraform Infra`

El workflow [`.github/workflows/terraform.yml`](../.github/workflows/terraform.yml) corre
Terraform contra Azure autenticándose con **`azure/login` (OIDC, sin contraseñas)** y con
**estado remoto** en Azure Storage. Hace `plan` siempre y `apply` en `push` a `main` o
`workflow_dispatch` (working-directory `terraform/`).

### 1) Bootstrap del estado remoto (una sola vez)

El nombre del storage account debe coincidir con [`backend.tfvars`](backend.tfvars)
(`tfstatedevsudemo`) y ser único global — ajústalo en ambos lados si hace falta.

```bash
az group create -n tfstate-rg -l eastus2
az storage account create -n tfstatedevsudemo -g tfstate-rg -l eastus2 \
  --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create -n tfstate --account-name tfstatedevsudemo --auth-mode login
```

### 2) App Registration + OIDC (una sola vez)

```bash
APP_ID=$(az ad app create --display-name "github-devsu-demo" --query appId -o tsv)
az ad sp create --id "$APP_ID"
SUB=$(az account show --query id -o tsv)

# Permisos: crear recursos + role assignments (AcrPull) + leer/escribir el estado remoto
az role assignment create --assignee "$APP_ID" --role "Owner" --scope "/subscriptions/$SUB"
az role assignment create --assignee "$APP_ID" --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUB/resourceGroups/tfstate-rg"

# Una sola federated credential: ambos workflows corren en la rama main
REPO="FrankBatista09/frank-reyes-devops-challenge"
az ad app federated-credential create --id "$APP_ID" --parameters "{\"name\":\"gh-main\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${REPO}:ref:refs/heads/main\",\"audiences\":[\"api://AzureADTokenExchange\"]}"
```

> El `client-id` que va en `AZURE_CLIENT_ID` es el **Application (client) ID** (`$APP_ID`),
> **no** el object ID del directorio. Como ni `terraform.yml` ni el job `deploy` de la app
> usan `environment`, ambos corren con el subject `...:ref:refs/heads/main`, por lo que basta
> **una** federated credential.

### 3) Configurar GitHub

Solo los 3 **Secrets** (ya creados). El backend no usa variables: sus valores viven en
[`backend.tfvars`](backend.tfvars) (config no sensible, versionada).

| Tipo | Nombre | Valor |
|------|--------|-------|
| Secret | `AZURE_CLIENT_ID` | Application (client) ID (`$APP_ID`) |
| Secret | `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| Secret | `AZURE_SUBSCRIPTION_ID` | `$SUB` |

Tras el primer `apply`, agregar las **Variables** `ACR_NAME`, `AKS_RESOURCE_GROUP` y
`AKS_CLUSTER_NAME` (de `terraform output`) para que el pipeline de la app despliegue.

## Teardown

```bash
terraform destroy -var-file=environments/production.tfvars
```

> Se entrega como código listo para aplicar; no se ejecutó aquí para no crear
> recursos facturables. La salida de `terraform apply`/`output` se adjunta al
> entregable como evidencia.
