# ScoutSuite
> Multi-cloud security auditing for AWS, Azure, GCP, and Kubernetes. Read-only API collection plus a rule engine that flags `danger`/`warning` findings into an HTML report and `scoutsuite-results` JS payloads. Use `--no-browser` for headless runs and `--local` to re-score fetched data offline.

<!-- tags: cloud,aws,kubernetes,scoutsuite,audit,enum -->

## scout aws caller identity
Confirm the identity Scout will use before launching a long run.

```bash
aws --profile {{PROFILE:str:default}} sts get-caller-identity
```

<!-- meta: risk=low | phase=recon | tags=aws,identity,preflight -->

---

## scout aws default credentials
Run Scout Suite against AWS using the default boto3/AWS CLI credential chain.

```bash
scout aws --no-browser
```

<!-- meta: risk=low | phase=recon | tags=aws,audit,default -->

---

## scout aws named profile
Run an AWS assessment against one named profile.

```bash
scout aws --profile {{PROFILE:str:default}} --no-browser
```

<!-- meta: risk=low | phase=recon | tags=aws,audit,profile -->

---

## scout aws environment keys
Run Scout Suite against AWS with access keys already exported in the environment.

```bash
AWS_ACCESS_KEY_ID={{ACCESS_KEY_ID:str:AKIAEXAMPLE}} AWS_SECRET_ACCESS_KEY={{SECRET_ACCESS_KEY:str:secret}} AWS_SESSION_TOKEN={{SESSION_TOKEN:str:token}} scout aws --no-browser
```

<!-- meta: risk=low | phase=recon | tags=aws,audit,credentials -->

---

## scout aws report to directory
Run an AWS assessment and write output to an engagement directory.

```bash
scout aws --profile {{PROFILE:str:default}} --report-dir {{OUTDIR:dir:scoutsuite-report}} --no-browser
```

<!-- meta: risk=low | phase=recon | tags=aws,audit,report -->

---

## scout aws custom ruleset
Run with an engagement-specific ruleset to emphasize red-team-relevant findings.

```bash
scout aws --profile {{PROFILE:str:default}} --ruleset {{RULESET:file:ruleset.json}} --report-dir {{OUTDIR:dir:scoutsuite-report}} --no-browser
```

<!-- meta: risk=low | phase=recon | tags=aws,audit,ruleset -->

---

## scout aws local reanalysis
Re-run the rule engine on previously fetched data without calling AWS APIs again.

```bash
scout aws --profile {{PROFILE:str:default}} --local --ruleset {{RULESET:file:ruleset.json}} --report-dir {{OUTDIR:dir:scoutsuite-report}} --no-browser
```

<!-- meta: risk=low | phase=misc | tags=aws,audit,local,offline -->

---

## scout results js to json
Strip the JavaScript variable assignment and save valid JSON for command-line triage.

```bash
tail -n +2 {{RESULTS_JS:file:scoutsuite-results/scoutsuite_results_aws.js}} > {{OUTFILE:file:scoutsuite-results.json}}
```

<!-- meta: risk=low | phase=misc | tags=triage,json,parse -->

---

## scout results danger findings
Search Scout Suite results JSON for danger-level findings.

```bash
jq '.. | objects | select(.level? == "danger")' {{RESULTS_JSON:file:scoutsuite-results.json}}
```

<!-- meta: risk=low | phase=recon | tags=triage,findings,danger -->

---

## scout results warning findings
Search Scout Suite results JSON for warning-level findings.

```bash
jq '.. | objects | select(.level? == "warning")' {{RESULTS_JSON:file:scoutsuite-results.json}}
```

<!-- meta: risk=low | phase=recon | tags=triage,findings,warning -->

---

## scout results service keys
List service keys present in a results file to map collected coverage.

```bash
jq -r '.services | keys[]' {{RESULTS_JSON:file:scoutsuite-results.json}}
```

<!-- meta: risk=low | phase=recon | tags=triage,services,enum -->

---

## scout results public exposure grep
Search extracted results for public, internet, unrestricted, anonymous, and wildcard indicators.

```bash
grep -RniE '0\.0\.0\.0/0|::/0|public|internet|unrestricted|anonymous|wildcard|\*' {{OUTDIR:dir:scoutsuite-report}}/scoutsuite-results
```

<!-- meta: risk=low | phase=recon | tags=triage,exposure,public -->

---

## scout aws iam grep
Search Scout Suite result payloads for IAM privilege and trust leads.

```bash
grep -RniE 'iam|admin|administrator|assume|trust|mfa|access.?key|policy|privilege' {{OUTDIR:dir:scoutsuite-report}}/scoutsuite-results
```

<!-- meta: risk=low | phase=recon | tags=aws,iam,triage,privesc -->

---

## scout aws s3 grep
Search Scout Suite result payloads for S3 bucket public, logging, or encryption findings.

```bash
grep -RniE 's3|bucket|public|anonymous|logging|encryption' {{OUTDIR:dir:scoutsuite-report}}/scoutsuite-results
```

<!-- meta: risk=low | phase=recon | tags=aws,s3,triage,exposure -->

---

## scout aws security groups jq
Pretty print EC2 security groups from Scout Suite JSON for manual exposure review.

```bash
jq '.services.ec2.regions[].vpcs[].security_groups[]?' {{RESULTS_JSON:file:scoutsuite-results.json}}
```

<!-- meta: risk=low | phase=recon | tags=aws,ec2,security-groups,exposure -->

---

## scout kubernetes named context
Run Scout Suite against a specific kubeconfig context.

```bash
scout kubernetes --context {{KUBE_CONTEXT:str:default}} --report-dir {{OUTDIR:dir:scoutsuite-report}} --no-browser
```

<!-- meta: risk=low | phase=recon | tags=kubernetes,audit,context -->

---

## scout kubernetes aws control plane
Scan Kubernetes with AWS provider support when the cluster is EKS-hosted and the AWS identity has required permissions.

```bash
scout kubernetes -c aws --context {{KUBE_CONTEXT:str:default}} --report-dir {{OUTDIR:dir:scoutsuite-report}} --no-browser
```

<!-- meta: risk=low | phase=recon | tags=kubernetes,aws,eks,audit -->

---

## scout kubernetes rbac grep
Search Kubernetes report data for RBAC and privileged access leads.

```bash
grep -RniE 'cluster-admin|clusterrole|rolebinding|serviceaccount|privileged|hostpath|hostnetwork|secret|token' {{OUTDIR:dir:scoutsuite-report}}/scoutsuite-results
```

<!-- meta: risk=low | phase=recon | tags=kubernetes,rbac,triage,privesc -->
