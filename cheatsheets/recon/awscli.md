# AWS CLI

> AWS IAM and resource enumeration using the AWS CLI for cloud penetration testing

<!-- tags: aws, awscli, iam, cloud, recon -->

---

## configure named profile
Configure a named AWS profile with access key, secret key, and region.

```bash
aws configure --profile {{PROFILE:str:assessment}}
```

<!-- meta: risk=safe | phase=misc | tags=configure,profile -->

---

## whoami caller identity sts
Verify which IAM principal is associated with the current credentials.

```bash
aws --profile {{PROFILE:str:assessment}} sts get-caller-identity
```

<!-- meta: risk=safe | phase=recon | tags=sts,whoami,identity -->

---

## list IAM users
Enumerate all IAM users on the AWS account.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-users
```

<!-- meta: risk=safe | phase=recon | tags=iam,users,enum -->

---

## list IAM groups for user
Show which IAM groups a user belongs to.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-groups-for-user --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,groups,user -->

---

## list attached user policies IAM
List managed policies attached directly to a user.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-attached-user-policies --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,policies,user -->

---

## list inline user policies IAM
List inline (embedded) policies on a user.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-user-policies --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,inline,policies -->

---

## check user console login IAM
Confirm whether a user has a console password configured.

```bash
aws --profile {{PROFILE:str:assessment}} iam get-login-profile --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,login,console -->

---

## list MFA devices
Identify MFA devices configured on the account.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-virtual-mfa-devices
```

<!-- meta: risk=safe | phase=recon | tags=mfa,security,iam -->

---

## list customer managed policies IAM
List only customer-managed policies for review.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-policies --scope Local | grep -A2 PolicyName
```

<!-- meta: risk=safe | phase=recon | tags=iam,policies,custom -->

---

## read policy document permissions
Retrieve the JSON document for a policy to inspect its permissions.

```bash
aws --profile {{PROFILE:str:assessment}} iam get-policy-version --policy-arn {{POLICY_ARN:str}} --version-id {{VERSION:str:v1}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,policy,document -->

---

## list IAM roles
List all IAM roles in the account.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-roles
```

<!-- meta: risk=safe | phase=recon | tags=iam,roles,enum -->

---

## read role trust policy assumerole
Inspect the assume-role policy of a role to see who can assume it.

```bash
aws --profile {{PROFILE:str:assessment}} iam get-role --role-name {{ROLE:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,trust,assumerole -->

---

## list user SSH keys codecommit
Look for IAM users with associated SSH keys (CodeCommit access).

```bash
aws --profile {{PROFILE:str:assessment}} iam list-ssh-public-keys --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,ssh,keys -->

---

## download user SSH key PEM
Download a user's SSH public key in PEM format.

```bash
aws --profile {{PROFILE:str:assessment}} iam get-ssh-public-key --user-name {{USERNAME:str}} --encoding PEM --ssh-public-key-id {{KEY_ID:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,ssh,download -->
