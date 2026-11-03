# threat-intel — Threat Intelligence Research

Query MITRE ATT&CK, CVE/NVD, OSV.dev, and Exploit-DB via REST APIs to map vulnerabilities to adversary techniques and generate detection rules.

## MITRE ATT&CK

### Fetch full matrix (STIX)
```bash
curl -s https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json | \
  jq '[.objects[] | select(.type == "attack-pattern") | {id: .id, name: .name, tactic: (.kill_chain_phases[]? | select(.phase_name != null) | .phase_name), description: .description, x_mitre_platforms}]'
```

### Search techniques by keyword
```bash
curl -s https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json | \
  jq '[.objects[] | select(.type == "attack-pattern" and (.name | test("logon"; "i")))] | .[] | {id: .id, name: .name, tactic: (.kill_chain_phases[]?.phase_name), url: .external_references[]?.url}'
```

### Get techniques by tactic
```bash
curl -s https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json | \
  jq '[.objects[] | select(.type == "attack-pattern" and (.kill_chain_phases[]?.phase_name == "initial-access"))] | .[] | .name'
```

### List all tactics
```bash
curl -s https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json | \
  jq '[.objects[] | select(.type == "x-mitre-tactic") | {name: .name, id: .id}]'
```

### Get software/tools used by adversaries
```bash
curl -s https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json | \
  jq '[.objects[] | select(.type == "malware" or .type == "tool") | {id: .id, name: .name, description: .description}]'
```

### Get mitigation/detection for a technique
```bash
curl -s https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json | \
  jq '[.objects[] | select(.type == "course-of-action") | {id: .id, name: .name, description: .description}]'
```

## CVE / NVD (National Vulnerability Database)

### Get CVE by ID
```bash
curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2024-3094" | \
  jq '{id: .vulnerabilities[0].cve.id, description: .vulnerabilities[0].cve.descriptions[0].value, cvss: .vulnerabilities[0].cve.metrics.cvssMetricV31[0].cvssData, cwe: .vulnerabilities[0].cve.weaknesses[0].description[0].value}'
```

### Search CVEs by keyword (e.g. product name)
```bash
curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=log4j&resultsPerPage=10" | \
  jq '[.vulnerabilities[] | {id: .cve.id, published: .cve.published, severity: .cve.metrics.cvssMetricV31[0].cvssData.baseSeverity, description: .cve.descriptions[0].value}]'
```

### Get CVEs for a specific product
```bash
curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=apache+http+server&resultsPerPage=10" | \
  jq '[.vulnerabilities[] | {id: .cve.id, published: .cve.published, cvss: .cve.metrics.cvssMetricV31[0].cvssData.baseScore}]'
```

## OSV.dev (Open Source Vulnerabilities)

### Query by package (ecosystem + version)
```bash
curl -s -X POST https://api.osv.dev/v1/query -H "Content-Type: application/json" -d '{"package": {"name": "lodash", "ecosystem": "npm"}, "version": "4.17.20"}' | \
  jq '[.vulns[]? | {id: .id, summary: .summary, severity: .database_specific?.severity}]'
```

### Query by commit hash
```bash
curl -s -X POST https://api.osv.dev/v1/query -H "Content-Type: application/json" -d '{"commit": "a1b2c3d4..."}' | \
  jq '.vulns[]?.id'
```

### Get all vulns for an ecosystem (paginated)
```bash
curl -s "https://api.osv.dev/v1/ecosystem/npm" | jq '.'
```

## Exploit-DB

### Search exploits by EDB-ID
```bash
curl -s "https://www.exploit-db.com/raw/51721" | head -50
```

### Search exploits via web
Use the built-in websearch or the `firecrawl` CLI with: `site:exploit-db.com <CVE-ID>`

### Local searchsploit (if installed)
```bash
searchsploit <cve-id or keyword> 2>/dev/null
searchsploit -t <title keyword>
```

## CVE → ATT&CK Mapping

### Step 1: Get CVE info
```bash
curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2024-3094" | jq '...'
```

### Step 2: Search MITRE ATT&CK for matching technique
Extract keywords from CVE description, then search ATT&CK:
```bash
curl -s https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json | \
  jq '[.objects[] | select(.type == "attack-pattern" and (.description | test("XSS|sql injection|RCE"; "i"))) | {name, tactic: (.kill_chain_phases[]?.phase_name)}]'
```

### Step 3: Build report
```
- CVE-2024-XXXX: description
  → ATT&CK: TXXXX.XXX (Tactic)
  → CVSS: 9.8 (CRITICAL)
  → Detection: [Sigma / YARA / Suricata rule link]
  → Mitigation: [reference to course-of-action]
```

## Detection Rules Sources

### Sigma (generic SIEM rules)
```bash
curl -s "https://raw.githubusercontent.com/SigmaHQ/sigma/master/rules/windows/process_creation/proc_creation_win_webshell_spawn.yml"
```

Search: `site:github.com/SigmaHQ/sigma <technique or keyword>`

### YARA (malware detection)
```bash
curl -s "https://raw.githubusercontent.com/YARAify/yararules/main/rules/malware/Log4J.yar"
```

Search: `site:github.com/yararules <keyword>`

## Quick Workflows

### 1. CVE lookup → ATT&CK mapping
```
1. curl NVD API for CVE details
2. Extract keywords (product, vuln type, CWE)
3. jq search ATT&CK STIX for matching technique
4. Build summary: CVE → Technique → Detection
```

### 2. Package vulnerability scan
```
1. OSV.dev query by package@version
2. For each vuln: NVD API for CVSS
3. Cross-reference with ATT&CK
4. Suggest mitigations
```

### 3. Threat group tracking
```
1. Get group info from ATT&CK STIX (type == "intrusion-set")
2. List their techniques (type == "attack-pattern", related via relationship object)
3. Map to CVEs targeting related software
```

### 4. Context chunking for 16K models
When target context exceeds whiterabbitneo's 16K limit:
```
1. Split data into chunks of ~12K tokens (leave 4K for instructions)
2. For each chunk: switch to whiterabbitneo → analyze → save partial results
3. Switch back to big-pickle → compile all partial results
4. Final report: merge findings, remove duplicates, rank by severity
```

**Chunking strategies:**
- **Files**: chunk per file (small files) or per 12K lines (large files)
- **Logs**: chunk by 1000 lines or timestamp windows
- **CVE lists**: chunk by 50 CVEs per batch
- **Network traffic**: chunk by protocol/stream
