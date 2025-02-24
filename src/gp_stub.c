#include "syscfg.h"

TBOOLEAN interactive = FALSE;
TBOOLEAN noinputfiles = FALSE;
TBOOLEAN reading_from_dash = FALSE;
const char *user_shell = NULL;
TBOOLEAN ctrlc_flag = FALSE;

void interrupt_setup(void) {}
void gp_expand_tilde(char **) {}
void restrict_popen(void) {}
