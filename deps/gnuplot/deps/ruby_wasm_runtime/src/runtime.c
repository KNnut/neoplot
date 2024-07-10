#include "setjmp.h"
#include "asyncify.h"
#include <stdlib.h>

int32_t rb_wasm_rt_start(int32_t (call)(size_t code_len, uint8_t type), size_t code_len, uint8_t type) {
  int32_t result;
  void *asyncify_buf;

  while (1) {
    result = call(code_len, type);

    extern void *rb_asyncify_unwind_buf;
    // Exit Asyncify loop if there is no unwound buffer, which
    // means that main function has returned normally.
    if (rb_asyncify_unwind_buf == NULL) {
      break;
    }

    // NOTE: it's important to call 'asyncify_stop_unwind' here instead in rb_wasm_handle_jmp_unwind
    // because unless that, Asyncify inserts another unwind check here and it unwinds to the root frame.
    asyncify_stop_unwind();

    if ((asyncify_buf = rb_wasm_handle_jmp_unwind()) != NULL) {
      asyncify_start_rewind(asyncify_buf);
      continue;
    }

    break;
  }
  return result;
}
