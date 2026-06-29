# dps/meta CHANGELOG

## v0.2.0 — 2026-06-29

### Breaking changes

None. The public CLI interface and all `git config meta.*` keys are unchanged.
Generated file paths (`policy/slsa.rego`, `policy/c_quality.rego`,
`policy/ast.rego`, `matrix_id.h`, `src/matrix-id.lisp`) are unchanged.

### Changes

**cispec.org upstream integration** — dps/meta no longer owns the content
of identity headers or Rego gates. All canonical content is now fetched
from `https://cispec.org` at scaffold-generation time.

- `dps/meta/identity/upstream.lisp` (new) — HTTP fetch layer via drakma;
  `fetch-matrix-id-h` and `fetch-matrix-id-lisp` extract code blocks from
  cispec.org Hugo Markdown pages and return ready-to-write strings.
- `dps/meta/policy/upstream.lisp` (new) — gate fetch layer; checks the
  cimatrix gate bundle cache (`~/.cache/cimatrix/gates/`, 24h TTL) before
  hitting `cispec.org/gates/`; `fetch-gate` returns Rego source for any
  gate path.
- `dps/meta/identity/c99.lisp` — `matrix-id-h-content` now delegates to
  `upstream:fetch-matrix-id-h`. Public API signature unchanged.
- `dps/meta/identity/lisp.lisp` — `matrix-id-lisp-content` now delegates
  to `upstream:fetch-matrix-id-lisp`. Public API signature unchanged.
- `dps/meta/policy/slsa.lisp` — `slsa-rego-content` delegates to
  `upstream:fetch-gate "slsa/provenance.rego"`.
- `dps/meta/policy/c-quality.lisp` — `c-quality-rego-content` delegates to
  `upstream:fetch-gate "c-quality/attribution.rego"`.
- `dps/meta/policy/ast.lisp` — `ast-rego-content` delegates to
  `upstream:fetch-gate "ast/forbidden-calls.rego"`.
- `dps/meta/attestation/upstream-specs.lisp` (new) — FiveAM specs for the
  upstream fetch layer. Set `CISPEC_OFFLINE=1` in CI to run against mock
  fixtures.
- `qlfile` — added `ql drakma` and `ql cl-mock`.

### Runtime behaviour change

`dps-meta` now requires network access to `cispec.org` on first run (or
when the cimatrix gate cache is stale). Subsequent runs within 24 hours
use the cimatrix cache and require no network access. Scaffold runs in
air-gapped environments must pre-populate `~/.cache/cimatrix/gates/`
manually or set `CISPEC_OFFLINE=1` (which uses the bundled fixtures, not
production content — for testing only).

### Why this is a MINOR not a MAJOR

No public interface changed. The generated file paths, content shape, and
`git config meta.*` input keys are all identical. The only observable
difference is that generated files now cite `cispec.org` as their canonical
source rather than having been generated inline.

## v0.1.1 — (prior release)

SLSA Level 3 attestation. See prior CHANGELOG.
