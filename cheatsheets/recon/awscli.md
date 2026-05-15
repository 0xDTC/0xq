# AWS CLI

> AWS IAM and resource enumeration using the AWS CLI for cloud penetration testing

<!-- tags: aws, awscli, iam, cloud, recon -->

---

## Configure New Profile
Configure a named AWS profile with access key, secret key, and region.

```bash
aws configure --profile {{PROFILE:str:assessment}}
```

<!-- meta: risk=safe | phase=misc | tags=configure,profile -->

---

## Caller Identity Check
Verify which IAM principal is associated with the current credentials.

```bash
aws --profile {{PROFILE:str:assessment}} sts get-caller-identity
```

<!-- meta: risk=safe | phase=recon | tags=sts,whoami,identity -->

---

## List IAM Users
Enumerate all IAM users on the AWS account.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-users
```

<!-- meta: risk=safe | phase=recon | tags=iam,users,enum -->

---

## List Groups for a User
Show which IAM groups a user belongs to.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-groups-for-user --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,groups,user -->

---

## List Attached User Policies
List managed policies attached directly to a user.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-attached-user-policies --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,policies,user -->

---

## List Inline User Policies
List inline (embedded) policies on a user.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-user-policies --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,inline,policies -->

---

## Check User Login Profile
Confirm whether a user has a console password configured.

```bash
aws --profile {{PROFILE:str:assessment}} iam get-login-profile --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,login,console -->

---

## List MFA Devices
Identify MFA devices configured on the account.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-virtual-mfa-devices
```

<!-- meta: risk=safe | phase=recon | tags=mfa,security,iam -->

---

## List All IAM Policies (Customer-Managed)
List only customer-managed policies for review.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-policies --scope Local | grep -A2 PolicyName
```

<!-- meta: risk=safe | phase=recon | tags=iam,policies,custom -->

---

## Get Policy Version Document
Retrieve the JSON document for a policy to inspect its permissions.

```bash
aws --profile {{PROFILE:str:assessment}} iam get-policy-version --policy-arn {{POLICY_ARN:str}} --version-id {{VERSION:str:v1}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,policy,document -->

---

## Enumerate Roles
List all IAM roles in the account.

```bash
aws --profile {{PROFILE:str:assessment}} iam list-roles
```

<!-- meta: risk=safe | phase=recon | tags=iam,roles,enum -->

---

## Get Role Trust Policy
Inspect the assume-role policy of a role to see who can assume it.

```bash
aws --profile {{PROFILE:str:assessment}} iam get-role --role-name {{ROLE:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,trust,assumerole -->

---

## List SSH Public Keys for User
Look for IAM users with associated SSH keys (CodeCommit access).

```bash
aws --profile {{PROFILE:str:assessment}} iam list-ssh-public-keys --user-name {{USERNAME:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,ssh,keys -->

---

## Get SSH Public Key (PEM)
Download a user's SSH public key in PEM format.

```bash
aws --profile {{PROFILE:str:assessment}} iam get-ssh-public-key --user-name {{USERNAME:str}} --encoding PEM --ssh-public-key-id {{KEY_ID:str}}
```

<!-- meta: risk=safe | phase=recon | tags=iam,ssh,download -->
