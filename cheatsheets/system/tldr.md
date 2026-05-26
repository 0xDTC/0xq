# tldr

> Community-driven simplified man pages with practical examples

<!-- tags: tldr, docs, manpages, reference -->

---

## install tldr
Install the tldr client from apt.

```bash
sudo apt install tldr -y
```

<!-- meta: risk=safe | phase=misc | tags=install,apt,tldr -->

---

## update tldr cache
Refresh the local tldr page cache.

```bash
tldr -u
```

<!-- meta: risk=safe | phase=misc | tags=update,cache -->

---

## show examples tldr
Print the tldr examples for a given command.

```bash
tldr {{TOOL:str:nmap}}
```

<!-- meta: risk=safe | phase=misc | tags=examples,reference -->

---

## render tldr markdown
Output the page as raw Markdown for piping/editing.

```bash
tldr --render {{TOOL:str:tar}}
```

<!-- meta: risk=safe | phase=misc | tags=render,markdown -->
