/* SPDX-License-Identifier: BSD-2-Clause
 * nob.c — build driver for dps-meta
 *
 * Bootstrap (one step):
 *   git submodule update --init && cc -o nob -I"./vendor/" nob.c && ./nob
 *
 * nob drives:
 *   1. qlot install        — pin dependency set
 *   2. opa check policy/   — Rego gate first (BDD)
 *   3. asdf:make :dps-meta — produce ./dps-meta binary
 *
 * Constraints (denzuko org, NASA Power of 10):
 *   No system(), popen(), exec*() — nob_cmd_run_sync uses execvp internally
 *   No static const char[] JSON
 *   C99, SPDX on every file
 *   NOB_GO_REBUILD_URSELF not used (per org standard)
 */

#define NOB_IMPLEMENTATION
#include <tsoding/nob.h/nob.h>

#define BINARY "dps-meta"

static int qlot_install(void)
{
    Nob_Cmd cmd = {0};
    nob_cmd_append(&cmd, "qlot", "install", NULL);
    int ok = nob_cmd_run_sync(cmd);
    nob_cmd_free(cmd);
    return ok;
}

static int opa_check(void)
{
    Nob_Cmd cmd = {0};
    nob_cmd_append(&cmd, "opa", "check", "policy/", NULL);
    int ok = nob_cmd_run_sync(cmd);
    nob_cmd_free(cmd);
    return ok;
}

static int build_binary(void)
{
    Nob_Cmd cmd = {0};
    nob_cmd_append(&cmd,
        "qlot", "exec", "ros", "run",
        "--eval", "(asdf:load-asd"
                  " (merge-pathnames #P\"dps-meta.asd\" (uiop:getcwd)))",
        "--eval", "(asdf:make :dps-meta)",
        "--eval", "(uiop:quit 0)",
        NULL);
    int ok = nob_cmd_run_sync(cmd);
    nob_cmd_free(cmd);
    return ok;
}

int main(void)
{
    nob_log(NOB_INFO, "dps-meta build");

    if (!qlot_install()) { nob_log(NOB_ERROR, "qlot install failed"); return 1; }
    if (!opa_check())    { nob_log(NOB_ERROR, "opa check failed");    return 1; }
    if (!build_binary()) { nob_log(NOB_ERROR, "build failed");        return 1; }

    nob_log(NOB_INFO, "done -> ./%s", BINARY);
    return 0;
}
