# SPDX-License-Identifier: BSD-2-Clause
# policy/slsa.rego — SLSA Level 3 provenance gate for dps-meta generated repos
#
# Gate contract:
#   input.predicate.buildType     must match expected build type URI
#   input.predicate.builder.id    must match a known trusted builder
#   input.predicate.materials     must be non-empty (source pinned)
#   input.subject                 must contain at least one named artifact
#   input.predicate.metadata.completeness.environment  must be true
#
# All rules are deny-by-default; allow only when every condition holds.

package dps.meta.slsa

import future.keywords.if
import future.keywords.in
import future.keywords.every

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

trusted_builders := {
    "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml",
    "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/builder_generic_slsa3.yml"
}

expected_build_type := "https://slsa.dev/provenance/v1"

# ---------------------------------------------------------------------------
# Top-level decision
# ---------------------------------------------------------------------------

default allow := false

allow if {
    count(violation) == 0
}

# ---------------------------------------------------------------------------
# Violation set — every named condition that fails surfaces here
# ---------------------------------------------------------------------------

violation contains msg if {
    not input.subject
    msg := "subject: missing — no artifact named in attestation"
}

violation contains msg if {
    input.subject
    count(input.subject) == 0
    msg := "subject: empty array — at least one artifact required"
}

violation contains msg if {
    not input.predicate
    msg := "predicate: missing from attestation"
}

violation contains msg if {
    input.predicate
    not input.predicate.buildType
    msg := "predicate.buildType: missing"
}

violation contains msg if {
    input.predicate.buildType
    input.predicate.buildType != expected_build_type
    msg := sprintf("predicate.buildType: got %q, expected %q",
                   [input.predicate.buildType, expected_build_type])
}

violation contains msg if {
    input.predicate
    not input.predicate.builder
    msg := "predicate.builder: missing"
}

violation contains msg if {
    input.predicate.builder
    not input.predicate.builder.id
    msg := "predicate.builder.id: missing"
}

violation contains msg if {
    input.predicate.builder.id
    not input.predicate.builder.id in trusted_builders
    msg := sprintf("predicate.builder.id: %q is not a trusted builder",
                   [input.predicate.builder.id])
}

violation contains msg if {
    input.predicate
    not input.predicate.materials
    msg := "predicate.materials: missing — source commit must be pinned"
}

violation contains msg if {
    input.predicate.materials
    count(input.predicate.materials) == 0
    msg := "predicate.materials: empty — source commit must be pinned"
}

violation contains msg if {
    some material in input.predicate.materials
    not material.uri
    msg := "predicate.materials[*].uri: at least one material missing uri"
}

violation contains msg if {
    some material in input.predicate.materials
    not material.digest
    msg := "predicate.materials[*].digest: at least one material missing digest"
}

violation contains msg if {
    input.predicate.metadata
    input.predicate.metadata.completeness
    input.predicate.metadata.completeness.environment != true
    msg := "predicate.metadata.completeness.environment: must be true for SLSA Level 3"
}
