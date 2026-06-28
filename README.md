<!-- SPDX-License-Identifier: BSD-2-Clause -->

# dps-meta

Standards scaffolding generator for the [denzuko](https://github.com/denzuko) GitHub organisation.

Distributed as a compiled binary and GitHub Action. Reads `git config meta.*` from a local
checkout and generates all required standards scaffolding into that checkout. The repo being
scaffolded owns itself — dps-meta only writes files.

## What it generates

For every repo type:

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | CI pipeline with OPA gate + SBOM jobs |
| `.github/workflows/slsa.yml` | SLSA Level 3 provenance triple |
| `.github/CODEOWNERS` | Ownership policy |
| `policy/slsa.rego` | SLSA provenance gate |
| `CLAUDE.md` | Project identity + standards reference |
| `CONTRIBUTING.md` | Contribution workflow |
| `SECURITY.md` | Vulnerability reporting + supply chain |
| `CODE_OF_CONDUCT.md` | Contributor Covenant v2.1 |
| `SUPPORT.md` | Support channels |
| `CHANGELOG.md` | Changelog stub |

C99 repos additionally get: `matrix_id.h`, `policy/c_quality.rego`, `policy/ast.rego`

Lisp repos additionally get: `src/matrix-id.lisp`

## Usage

Configure the target repo, then invoke the Action:

```sh
# In the target repo:
git config meta.type        c99-binary
git config meta.application my-tool
git config meta.role        build-tool
git config meta.version     0.1.0
git config meta.branch      main
git config meta.licence     bsd-2-clause
```

```yaml
# .github/workflows/scaffold.yml
- uses: denzuko/dps-meta@v1
  with:
    type: c99-binary
```

## Build

```sh
qlot install
cc -o nob nob.c && ./nob
```

## Standards

- SLSA Level 3 provenance
- OPA/Rego policy gates
- CycloneDX SBOM via cdxgen
- net.matrix CMDB identity baked into binary
- BSD 2-Clause throughout
- BDD-first: gate → spec → implementation

## Licence

BSD 2-Clause. See `SPDX-License-Identifier` in each file.
