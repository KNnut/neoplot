#include "syscfg.h"

extern TBOOLEAN interactive = FALSE;
extern TBOOLEAN noinputfiles = FALSE;
extern TBOOLEAN reading_from_dash = FALSE;

extern const char *user_shell = NULL;
extern TBOOLEAN ctrlc_flag = FALSE;

void interrupt_setup(void) {}
void gp_expand_tilde(char **) {}
void restrict_popen(void) {}
