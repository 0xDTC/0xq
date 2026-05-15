# Git

> Distributed version control for source code management and collaboration

<!-- tags: git, version-control, source, repo, branch -->

---

## Clone Repository
Clone a remote repository to the local machine.

```bash
git clone {{URL:url:https://github.com/user/repo.git}} {{DIR:dir:./repo}}
```

<!-- meta: risk=safe | phase=misc | tags=clone,download,repo -->

---

## Status and Diff
Show working tree status and unstaged changes.

```bash
git status && git diff
```

<!-- meta: risk=safe | phase=misc | tags=status,diff,changes -->

---

## Add and Commit
Stage files and create a commit with a message.

```bash
git add {{FILES:str:.}} && git commit -m "{{MSG:str:update}}"
```

<!-- meta: risk=low | phase=misc | tags=add,commit,stage -->

---

## Push and Pull
Push local commits to remote or pull latest changes.

```bash
git push origin {{BRANCH:str:main}} && git pull origin {{BRANCH:str:main}}
```

<!-- meta: risk=low | phase=misc | tags=push,pull,sync -->

---

## Branch Management
Create, switch to, or list branches.

```bash
git checkout -b {{BRANCH:str:feature}} && git branch -a
```

<!-- meta: risk=low | phase=misc | tags=branch,checkout,create -->

---

## Log One-Line Graph
View commit history as a compact graph.

```bash
git log --oneline --graph --all -n {{COUNT:int:20}}
```

<!-- meta: risk=safe | phase=misc | tags=log,graph,history -->

---

## Stash Changes
Temporarily save uncommitted changes and restore them later.

```bash
git stash push -m "{{MSG:str:wip}}" && git stash list
```

<!-- meta: risk=low | phase=misc | tags=stash,save,temporary -->

---

## Reset to Commit
Reset the branch to a previous commit (mixed keeps changes unstaged).

```bash
git reset --{{MODE:str:mixed}} {{COMMIT:str:HEAD~1}}
```

<!-- meta: risk=high | phase=misc | tags=reset,undo,revert -->

---

## Cherry-Pick Commit
Apply a specific commit from another branch onto the current branch.

```bash
git cherry-pick {{COMMIT:str:abc1234}}
```

<!-- meta: risk=low | phase=misc | tags=cherry-pick,apply,commit -->

---

## Diff Between Branches
Show the differences between two branches.

```bash
git diff {{BRANCH1:str:main}}..{{BRANCH2:str:feature}}
```

<!-- meta: risk=safe | phase=misc | tags=diff,compare,branches -->
