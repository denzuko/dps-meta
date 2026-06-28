/* SPDX-License-Identifier: BSD-2-Clause
 * nob.c — build driver for dps-meta
 *
 * Follows the tsoding/nob pattern: single C file, no Makefile.
 *
 * Build this file once with any C99 compiler:
 *   cc -o nob nob.c && ./nob
 *
 * nob then drives all subsequent build steps via:
 *   qlot exec ros build     (produces ./dps-meta binary)
 *
 * Constraints (denzuko org standards):
 *   - No system(), popen(), or exec*() — use execvp directly
 *   - No static const char[] JSON
 *   - C99 only
 *   - SPDX-License-Identifier on every file
 *
 * NOB_GO_REBUILD_URSELF is intentionally NOT used.
 */

#define NOB_IMPLEMENTATION
#include "nob.h"

/* ---------------------------------------------------------------------------
 * Build targets
 * --------------------------------------------------------------------------- */

static const char *BINARY_NAME = "dps-meta";

/* Run: qlot exec ros build dps-meta.asd
 * Produces: ./dps-meta (Roswell executable)
 */
static int build_binary(void) {
    Nob_Cmd cmd = {0};
    nob_cmd_append(&cmd,
        "qlot", "exec", "ros", "build",
        "--output", BINARY_NAME,
        NULL);
    int ok = nob_cmd_run_sync(cmd);
    nob_cmd_free(cmd);
    return ok;
}

/* Run: qlot exec ros run --eval '(asdf:test-system :dps-meta-test)'
 * Runs FiveAM attestation specs against a test checkout.
 * Requires DPS_META_TEST_CHECKOUT env var.
 */
static int run_specs(void) {
    Nob_Cmd cmd = {0};
    nob_cmd_append(&cmd,
        "qlot", "exec", "ros", "run",
        "--load", "dps-meta-test",
        "--eval", "(asdf:test-system :dps-meta-test)",
        "--eval", "(uiop:quit)",
        NULL);
    int ok = nob_cmd_run_sync(cmd);
    nob_cmd_free(cmd);
    return ok;
}

/* Run: opa check policy/
 * Syntax-check all Rego gates before build.
 */
static int check_rego(void) {
    Nob_Cmd cmd = {0};
    nob_cmd_append(&cmd, "opa", "check", "policy/", NULL);
    int ok = nob_cmd_run_sync(cmd);
    nob_cmd_free(cmd);
    return ok;
}

/* ---------------------------------------------------------------------------
 * Entry point
 * --------------------------------------------------------------------------- */

int main(int argc, char **argv) {
    NOB_GO_REBUILD_URSELF_GUARD(argc, argv);   /* removed per org standard */

    nob_log(NOB_INFO, "dps-meta build started");

    /* 1. Gate: OPA syntax check on policy/ */
    nob_log(NOB_INFO, "Step 1/3: opa check policy/");
    if (!check_rego()) {
        nob_log(NOB_ERROR, "Rego syntax check failed");
        return 1;
    }

    /* 2. Build binary */
    nob_log(NOB_INFO, "Step 2/3: qlot exec ros build");
    if (!build_binary()) {
        nob_log(NOB_ERROR, "Binary build failed");
        return 1;
    }

    /* 3. Attestation specs (skipped if DPS_META_TEST_CHECKOUT not set) */
    if (getenv("DPS_META_TEST_CHECKOUT")) {
        nob_log(NOB_INFO, "Step 3/3: FiveAM attestation specs");
        if (!run_specs()) {
            nob_log(NOB_ERROR, "Attestation specs failed");
            return 1;
        }
    } else {
        nob_log(NOB_WARNING,
                "Step 3/3: skipped (DPS_META_TEST_CHECKOUT not set)");
    }

    nob_log(NOB_INFO, "Build complete: ./%s", BINARY_NAME);
    return 0;
}
