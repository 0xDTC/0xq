# mitmproxy

> Interactive HTTP/HTTPS proxy for traffic inspection and manipulation

<!-- tags: mitm,proxy,http,https,interception -->

---

## launch interactive proxy ui
Launch mitmproxy in interactive terminal mode.

```bash
mitmproxy -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=interactive,ui -->

---

## dump traffic cli
Non-interactive console dump of proxied traffic.

```bash
mitmdump -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=cli,dump -->

---

## launch web ui
Browser-based mitmproxy UI.

```bash
mitmweb -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=web,ui -->

---

## proxy reverse mode
Forward all client traffic to a target host.

```bash
mitmproxy --mode reverse:{{TARGET_URL:url}} -p {{PORT:port:8080}}
```

<!-- meta: risk=med | phase=exploit | tags=reverse-proxy -->

---

## chain upstream proxy
Chain mitmproxy through another upstream proxy.

```bash
mitmproxy --mode upstream:{{UPSTREAM_URL:url}} -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=upstream,chain -->

---

## hook flows python script
Hook flows through a Python script for manipulation.

```bash
mitmproxy -s {{SCRIPT:file:script.py}} -p {{PORT:port:8080}}
```

<!-- meta: risk=med | phase=exploit | tags=script,hook -->

---

## save flows file
Capture and save all flows for later analysis.

```bash
mitmdump -w {{OUTFILE:file:capture.mitm}} -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=capture,save -->

---

## replay captured flows
Replay saved flows for testing.

```bash
mitmdump -r {{INFILE:file:capture.mitm}}
```

<!-- meta: risk=safe | phase=recon | tags=replay -->

---

## allow external connections
Disable global block so other machines can route through.

```bash
mitmproxy --set block_global=false -p {{PORT:port:8080}}
```

<!-- meta: risk=med | phase=recon | tags=external,access -->
