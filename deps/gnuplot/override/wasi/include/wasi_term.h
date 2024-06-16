#define GP_ENH_EST 1        /* estimate string length of enhanced text */
#include "estimate.trm"     /* used for enhanced text processing */

/* Unicode escape sequences (\U+hhhh) are handling by the enhanced text code.
 * Various terminals check every string to see whether it needs enhanced text
 * processing. This macro allows them to include a check for the presence of
 * unicode escapes.
 */
#define contains_unicode(S) strstr(S, "\\U+")

/* W3C Scalable Vector Graphics file */
#include "pure_svg.trm"

#define DEFAULTTERM "svg"
