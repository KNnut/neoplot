#include "syscfg.h"

extern TBOOLEAN interactive;
extern TBOOLEAN noinputfiles;
extern TBOOLEAN reading_from_dash;
extern const char *user_shell;
extern TBOOLEAN ctrlc_flag;

TBOOLEAN interactive = FALSE;
TBOOLEAN noinputfiles = FALSE;
TBOOLEAN reading_from_dash = FALSE;
const char *user_shell = NULL;
TBOOLEAN ctrlc_flag = FALSE;

void interrupt_setup(void) {}
void gp_expand_tilde(char **) {}
void restrict_popen(void) {}
