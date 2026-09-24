# Git

> Distributed version control for source code management and collaboration

<!-- tags: git, version-control, source, repo, branch -->

---

## clone repository
Clone a remote repository to the local machine.

```bash
git clone {{URL:url:https://github.com/user/repo.git}} {{DIR:dir:./repo}}
```

<!-- meta: risk=safe | phase=misc | tags=clone,download,repo -->

---

## show status and diff
Show working tree status and unstaged changes.

```bash
git status && git diff
```

<!-- meta: risk=safe | phase=misc | tags=status,diff,changes -->

---

## stage and commit changes
Stage files and create a commit with a message.

```bash
git add {{FILES:str:.}} && git commit -m "{{MSG:str:update}}"
```

<!-- meta: risk=low | phase=misc | tags=add,commit,stage -->

---

## push and pull branch
Push local commits to remote or pull latest changes.

```bash
git push origin {{BRANCH:choice:main=default branch,master=legacy default,develop=integration branch,dev=short develop,staging=pre-prod,production=live release}} && git pull origin {{BRANCH:choice:main=default branch,master=legacy default,develop=integration branch,dev=short develop,staging=pre-prod,production=live release}}
```

<!-- meta: risk=low | phase=misc | tags=push,pull,sync -->

---

## create switch list branches
Create, switch to, or list branches.

```bash
git checkout -b {{BRANCH:str:feature}} && git branch -a
```

<!-- meta: risk=low | phase=misc | tags=branch,checkout,create -->

---

## view commit history graph
View commit history as a compact graph.

```bash
git log --oneline --graph --all -n {{COUNT:int:20}}
```

<!-- meta: risk=safe | phase=misc | tags=log,graph,history -->

---

## stash uncommitted changes
Temporarily save uncommitted changes and restore them later.

```bash
git stash push -m "{{MSG:str:wip}}" && git stash list
```

<!-- meta: risk=low | phase=misc | tags=stash,save,temporary -->

---

## reset to commit undo
Reset the branch to a previous commit (mixed keeps changes unstaged).

```bash
git reset --{{MODE:choice:mixed=unstage keep changes,soft=keep staged edits,hard=discard all changes,keep=keep unindexed edits,merge=keep unmerged files}} {{COMMIT:str:HEAD~1}}
```

<!-- meta: risk=high | phase=misc | tags=reset,undo,revert -->

---

## cherry-pick commit
Apply a specific commit from another branch onto the current branch.

```bash
git cherry-pick {{COMMIT:str:abc1234}}
```

<!-- meta: risk=low | phase=misc | tags=cherry-pick,apply,commit -->

---

## diff between branches
Show the differences between two branches.

```bash
git diff {{BRANCH1:choice:main=default branch,master=legacy default,develop=integration branch,dev=short develop,staging=pre-prod,production=live release}}..{{BRANCH2:str:feature}}
```

<!-- meta: risk=safe | phase=misc | tags=diff,compare,branches -->

## set git identity local or global
Configure user.name + user.email either for the current repo (`--local`) or machine-wide (`--global`). Ends with a readback so you can confirm what was set.

```bash
git config {{SCOPE:choice:--local=this repo only,--global=whole machine}} user.name "{{NAME:str}}" && git config {{SCOPE:choice:--local=this repo only,--global=whole machine}} user.email "{{EMAIL:str}}" && git config {{SCOPE:choice:--local=this repo only,--global=whole machine}} --get-regexp '^user\.'
```

<!-- meta: risk=low | phase=setup | tags=git,config,identity,local,global -->

---

## dump every deleted file ever
Every commit that deleted a file, listing which files vanished. Great for "wait, wasn't there a `secrets.yaml` here?".

```bash
git log --diff-filter=D --name-only --format='=== %h %s ===' | less
```

<!-- meta: risk=low | phase=recon | tags=git,history,deleted,secrets -->

---

## checkout file from past commit
Print the exact contents of one file at a specific commit — recover a file that was later deleted or rewritten.

```bash
git show {{COMMIT:str:HEAD}}:{{PATH:str:config/secrets.yaml}}
```

<!-- meta: risk=low | phase=recon | tags=git,show,past,recover -->
