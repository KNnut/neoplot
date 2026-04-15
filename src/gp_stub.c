#include "syscfg.h"

TBOOLEAN interactive = FALSE;
TBOOLEAN noinputfiles = FALSE;
TBOOLEAN reading_from_dash = FALSE;
TBOOLEAN ctrlc_flag = FALSE;

void interrupt_setup(void) {}
void gp_expand_tilde(char **) {}
