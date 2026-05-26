# CloudFox
> Cloud attack-surface and privesc-path enumeration for AWS, Azure, and GCP. Output (CSV/JSON/loot) lands under `cloudfox-output/<provider>/<profile>/`; loot files contain ready-to-run follow-up commands. Most checks are read-only API enumeration.

<!-- tags: cloud,aws,azure,gcp,cloudfox,enum,privesc -->

## cloudfox aws all-checks
Run most AWS checks against one profile and write table, CSV, JSON, and loot output locally.

```bash
cloudfox aws --profile {{PROFILE:str:default}} all-checks
```

<!-- meta: risk=low | phase=recon | tags=aws,all-checks,enum -->

---

## cloudfox aws all-checks output dir
Run all checks and write output under an engagement-specific directory.

```bash
cloudfox aws --profile {{PROFILE:str:default}} --outdir {{OUTDIR:dir:cloudfox-output}} all-checks
```

<!-- meta: risk=low | phase=recon | tags=aws,all-checks,output -->

---

## cloudfox aws inventory
Find which supported services and regions appear active before deeper enumeration.

```bash
cloudfox aws --profile {{PROFILE:str:default}} inventory
```

<!-- meta: risk=low | phase=recon | tags=aws,inventory,enum -->

---

## cloudfox aws principals
List IAM users and roles for target selection and role-chaining analysis.

```bash
cloudfox aws --profile {{PROFILE:str:default}} principals
```

<!-- meta: risk=low | phase=recon | tags=aws,iam,principals -->

---

## cloudfox aws permissions
Enumerate unique IAM permissions for users and roles.

```bash
cloudfox aws --profile {{PROFILE:str:default}} permissions
```

<!-- meta: risk=low | phase=recon | tags=aws,iam,permissions -->

---

## cloudfox aws access-keys
Map active IAM access key IDs to users; seed material for repo, Slack, drive, and secret-store searches.

```bash
cloudfox aws --profile {{PROFILE:str:default}} access-keys
```

<!-- meta: risk=low | phase=recon | tags=aws,iam,access-keys -->

---

## cloudfox aws access-keys filter
Identify whether a discovered AWS access key ID belongs to the in-scope account.

```bash
cloudfox aws --profile {{PROFILE:str:default}} access-keys --filter {{ACCESS_KEY_ID:str:AKIAEXAMPLE}}
```

<!-- meta: risk=low | phase=recon | tags=aws,iam,access-keys -->

---

## cloudfox aws role-trusts
Enumerate roles that trust principals, services, or federated identities; review `IsAdmin?` and `CanPrivEscToAdmin?` columns.

```bash
cloudfox aws --profile {{PROFILE:str:default}} role-trusts
```

<!-- meta: risk=low | phase=recon | tags=aws,iam,role-trusts,privesc -->

---

## cloudfox aws resource-trusts
Enumerate resource policies for offensively prioritized services: S3, SNS, SQS, Lambda, ECR, EFS, Glue, CodeBuild, Secrets Manager.

```bash
cloudfox aws --profile {{PROFILE:str:default}} resource-trusts
```

<!-- meta: risk=low | phase=recon | tags=aws,resource-trusts,policy -->

---

## cloudfox aws iam-simulator
Run IAM simulator checks for high-value actions; slow, but produces pmapper follow-up commands.

```bash
cloudfox aws --profile {{PROFILE:str:default}} iam-simulator --action {{ACTION:str:s3:GetObject}}
```

<!-- meta: risk=low | phase=recon | tags=aws,iam,simulator,privesc -->

---

## cloudfox aws pmapper
Use local pmapper graph data to identify principals with admin or paths to admin.

```bash
cloudfox aws --profile {{PROFILE:str:default}} pmapper
```

<!-- meta: risk=low | phase=recon | tags=aws,pmapper,privesc -->

---

## cloudfox aws endpoints
Enumerate internet-facing and internal endpoints from App Runner, API Gateway, CloudFront, EKS, ELB, Lambda, MQ, OpenSearch, Redshift, and RDS.

```bash
cloudfox aws --profile {{PROFILE:str:default}} endpoints
```

<!-- meta: risk=low | phase=recon | tags=aws,endpoints,attack-surface -->

---

## cloudfox aws network-ports
Enumerate security-group-exposed ports and produce target lists for service testing.

```bash
cloudfox aws --profile {{PROFILE:str:default}} network-ports
```

<!-- meta: risk=low | phase=recon | tags=aws,network,ports,attack-surface -->

---

## cloudfox aws instances
List EC2 instances, IPs, roles, and generated public/private IP loot files.

```bash
cloudfox aws --profile {{PROFILE:str:default}} instances
```

<!-- meta: risk=low | phase=recon | tags=aws,ec2,instances -->

---

## cloudfox aws workloads
Find EC2, ECS, Lambda, and App Runner workloads with admin roles or paths to admin.

```bash
cloudfox aws --profile {{PROFILE:str:default}} workloads
```

<!-- meta: risk=low | phase=recon | tags=aws,workloads,privesc -->

---

## cloudfox aws env-vars
Collect environment variables from App Runner, ECS, Lambda, Lightsail Containers, and SageMaker for secret hunting.

```bash
cloudfox aws --profile {{PROFILE:str:default}} env-vars
```

<!-- meta: risk=low | phase=recon | tags=aws,env-vars,secrets -->

---

## cloudfox aws lambda
List Lambda functions and generate get-function commands for code retrieval.

```bash
cloudfox aws --profile {{PROFILE:str:default}} lambda
```

<!-- meta: risk=low | phase=recon | tags=aws,lambda,loot -->

---

## cloudfox aws ecs-tasks
List ECS task definitions, roles, IPs, and useful ECS loot files.

```bash
cloudfox aws --profile {{PROFILE:str:default}} ecs-tasks
```

<!-- meta: risk=low | phase=recon | tags=aws,ecs,tasks -->

---

## cloudfox aws eks
Enumerate EKS clusters and generate kubeconfig update commands.

```bash
cloudfox aws --profile {{PROFILE:str:default}} eks
```

<!-- meta: risk=low | phase=recon | tags=aws,eks,kubernetes -->

---

## cloudfox aws ecr
Enumerate ECR repos and generate docker pull/login commands.

```bash
cloudfox aws --profile {{PROFILE:str:default}} ecr
```

<!-- meta: risk=low | phase=recon | tags=aws,ecr,docker,loot -->

---

## cloudfox aws buckets
List S3 buckets and generate commands for selective listing or download with whichever profile later has object access.

```bash
cloudfox aws --profile {{PROFILE:str:default}} buckets
```

<!-- meta: risk=low | phase=recon | tags=aws,s3,buckets,loot -->

---

## cloudfox aws secrets
List Secrets Manager and SSM Parameter Store secrets and generate pull commands for later use with stronger credentials.

```bash
cloudfox aws --profile {{PROFILE:str:default}} secrets
```

<!-- meta: risk=low | phase=recon | tags=aws,secrets,ssm,loot -->

---

## cloudfox aws databases
Enumerate AWS database services for data target selection.

```bash
cloudfox aws --profile {{PROFILE:str:default}} databases
```

<!-- meta: risk=low | phase=recon | tags=aws,databases,data -->

---

## cloudfox aws ram
Find inbound and outbound AWS RAM resource shares that can create cross-account attack paths.

```bash
cloudfox aws --profile {{PROFILE:str:default}} ram
```

<!-- meta: risk=low | phase=recon | tags=aws,ram,cross-account -->

---

## cloudfox aws orgs
Enumerate AWS Organizations accounts, management account context, OUs, and service control policy clues.

```bash
cloudfox aws --profile {{PROFILE:str:default}} orgs
```

<!-- meta: risk=low | phase=recon | tags=aws,organizations,cross-account -->

---

## cloudfox aws outbound-assumed-roles
Look for roles in other accounts that this account's principals can assume (excluded from all-checks because it is slow).

```bash
cloudfox aws --profile {{PROFILE:str:default}} outbound-assumed-roles
```

<!-- meta: risk=low | phase=recon | tags=aws,assume-role,cross-account,privesc -->

---

## cloudfox aws cape admin-only
Find cross-account privilege escalation paths that lead to admin across a profile list.

```bash
cloudfox aws -l {{PROFILE_FILE:file:profiles.txt}} cape --admin-only
```

<!-- meta: risk=med | phase=recon | tags=aws,cape,cross-account,privesc -->

---

## cloudfox gcp all-checks
Run all GCP checks against one project.

```bash
cloudfox gcp --project {{PROJECT_ID:str:my-project}} all-checks
```

<!-- meta: risk=low | phase=recon | tags=gcp,all-checks,enum -->

---

## cloudfox azure vms
Enumerate Azure virtual machines against a subscription.

```bash
cloudfox azure --subscription {{SUBSCRIPTION_ID:str:00000000-0000-0000-0000-000000000000}} vms
```

<!-- meta: risk=low | phase=recon | tags=azure,vms,enum -->
