# API Gateway Terraform

## Descrição

Esse repositório contém os códigos Terraform de Api Gateway na AWS utilizada na fase do techchallenge.

Todo provisionamento foi feito asssumindo-se que AWS Academy está sendo utilizado.  AWS Academy não permite a criação de IAM roles ou qualquer outro recurso relacioado a AWS IAM. Sendo assim, em todos os módulos é utilizado o role LabRole pre-existente na AWS Academy.

As seguintes tarefas são realizadas por esse código Terradorm:

* Através do módulo api-gateway: Provisionamento da infra da rede (VPC, subnet, Internet Gateway, route table e NAT)

## Este repositório NÃO contém pipeline de destroy, pipe de destroy está no repositório de infraestrutura.

## Fazendo Deployment via ACTION

O action 'terraform apply' pode ser usado para realizar o deployment do Api Gateway.

1. Execute antes o pipeline de infraestrutura para criar o ambiente EKS
2. Execute tambem a pipeline de infraestrutura para criar o ambiente RDS
3. Execute tambem a pipeline de deploy das aplicações 
4. Excute o pipeline de deploy do Api Gateway
2. Execute o seguinte comando para configurar as credenciais do cluster EKS na sua máquina e poder executar comandos com kubectl
```bash
aws eks --region us-east-1 update-kubeconfig --name techchallenge
```
### Lembre-se de executar a pipe 'terraform destroy' ao final dos testes

## Testando na máquina local aponta para o ambiente AWS Academy

1. Inicialize o laboratório no AWS Academy
2. Copie as credenciais disponíveis em AWS Details (ver AWS CLI em CLoud Access) para o arquivo ~/.aws/credentials da sua máquina
3. Comente o blco  do s3 backend no arquivo provider.tf
5. Execute 'terraform init':
```bash
terraform init
```
6. Execute 'terraform apply' para subir a infraestrutura:
```bash
  terraform apply
```
7. Execute o seguinte comando de deploy da aplicação:
```bash
  terraform destroy
```

### Lembre-se de executar 'terraform destroy' ao final dos testes

## Obtendo ip do Api Gateway

1. Execute o seguinte comando para obter o ip do Api Gateway
```bash
aws apigatewayv2 get-apis
```