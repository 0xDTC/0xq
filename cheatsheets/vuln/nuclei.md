# Nuclei

> Fast, template-based vulnerability scanner. Trimmed to three focused commands. Every entry pins a real-browser User-Agent — nuclei's default UA is instantly flagged by every WAF worth its salt.

<!-- tags: nuclei, vuln, cve, misconfig, scan, exposure, dast -->

> **UA policy** — every command below uses `-H "User-Agent: ..."` with a real Chrome-on-Windows string as the default. At fill time, override with a Firefox or Safari string if you prefer — pick ONE UA per invocation, never stack them.
>
> Ready-to-paste alternatives:
>
> - **Firefox 128 Linux:** `Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0`
> - **Safari 17 macOS:** `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15`

---

## nuclei tech aware cve misconfig exposure
Chain: whatweb visibility → nuclei -as (wappalyzer picks templates matching the detected tech) restricted to CVE + misconfig + exposure + disclosure + default-login tags. The default scan — checks the target based on what it actually runs, without wasting cycles on irrelevant templates.

```bash
url={{URL:url}}; ua={{UA:str:$(q-ua)}}; echo '[+] whatweb tech fingerprint'; whatweb -a3 --user-agent="$ua" "$url" 2>/dev/null | tr ',' '\n' | head -15; echo; echo '[+] nuclei -as + tag filter (cve,misconfig,exposure,disclosure,default-login)'; nuclei -u "$url" -as -tags cve,misconfig,exposure,disclosure,default-login -H "User-Agent: $ua" -stats -si 15 -duc -jle {{OUT:file:nuclei-tech.jsonl}} 2>&1 | tail -20
```

<!-- meta: risk=low | phase=enum | tags=nuclei,whatweb,as,cve,misconfig,exposure,disclosure,default-login,chain -->

---

## nuclei via burp caido proxy
Same tech-aware scan, routed through your local intercepting proxy (Burp/Caido on 127.0.0.1:8080). Every request lands in your history for review, replay, or manual follow-up.

```bash
url={{URL:url}}; ua={{UA:str:$(q-ua)}}; proxy={{PROXY:url:http://127.0.0.1:8080}}; echo "[+] nuclei -as via $proxy (Burp/Caido)"; nuclei -u "$url" -as -tags cve,misconfig,exposure,disclosure,default-login -H "User-Agent: $ua" -proxy "$proxy" -stats -si 15 -duc -jle {{OUT:file:nuclei-via-proxy.jsonl}} 2>&1 | tail -20
```

<!-- meta: risk=low | phase=enum | tags=nuclei,proxy,burp,caido,chain -->

---

## nuclei simple full scan
Just a URL in, complete scan out. No tag filters, no tech restriction — the loudest, most thorough pass across every enabled template. Use when you have permission and time.

```bash
url={{URL:url}}; ua={{UA:str:$(q-ua)}}; echo '[+] nuclei full-scan (all severities, all templates)'; nuclei -u "$url" -H "User-Agent: $ua" -stats -si 15 -duc -jle {{OUT:file:nuclei-full.jsonl}} 2>&1 | tail -20
```

<!-- meta: risk=medium | phase=enum | tags=nuclei,full,complete -->
