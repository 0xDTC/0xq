# q

> q itself — utility commands for the launcher. `q --help` is the full reference; this file collects the ones worth having in fzf when you're mid-flow.

<!-- tags: q,launcher,util,index -->

## rebuild fzf index
Force q to re-scan `cheatsheets/` and refresh `cache/index.tsv`. Run after adding, editing, or removing a `.md` file when you don't want to wait for the automatic checksum-triggered rebuild.

```bash
q rebuild
```

<!-- meta: risk=safe | phase=util | tags=q,rebuild,index -->
