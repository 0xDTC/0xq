# mitmproxy

> Interactive HTTP/HTTPS proxy for traffic inspection and manipulation

<!-- tags: mitm,proxy,http,https,interception -->

---

## Interactive UI
Launch mitmproxy in interactive terminal mode.

```bash
mitmproxy -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=interactive,ui -->

---

## CLI Dump Mode
Non-interactive console dump of proxied traffic.

```bash
mitmdump -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=cli,dump -->

---

## Web Interface
Browser-based mitmproxy UI.

```bash
mitmweb -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=web,ui -->

---

## Reverse Proxy Mode
Forward all client traffic to a target host.

```bash
mitmproxy --mode reverse:{{TARGET_URL:url}} -p {{PORT:port:8080}}
```

<!-- meta: risk=med | phase=exploit | tags=reverse-proxy -->

---

## Upstream Proxy Mode
Chain mitmproxy through another upstream proxy.

```bash
mitmproxy --mode upstream:{{UPSTREAM_URL:url}} -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=upstream,chain -->

---

## Run with Custom Script
Hook flows through a Python script for manipulation.

```bash
mitmproxy -s {{SCRIPT:file:script.py}} -p {{PORT:port:8080}}
```

<!-- meta: risk=med | phase=exploit | tags=script,hook -->

---

## Save All Flows to File
Capture and save all flows for later analysis.

```bash
mitmdump -w {{OUTFILE:file:capture.mitm}} -p {{PORT:port:8080}}
```

<!-- meta: risk=safe | phase=recon | tags=capture,save -->

---

## Replay Captured Flows
Replay saved flows for testing.

```bash
mitmdump -r {{INFILE:file:capture.mitm}}
```

<!-- meta: risk=safe | phase=recon | tags=replay -->

---

## Allow External Connections
Disable global block so other machines can route through.

```bash
mitmproxy --set block_global=false -p {{PORT:port:8080}}
```

<!-- meta: risk=med | phase=recon | tags=external,access -->
