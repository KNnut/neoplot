#include <wasi/api.h>

int32_t __imported_wasi_snapshot_preview1_environ_get(int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_environ_sizes_get(__wasi_size_t* retptr0, __wasi_size_t* retptr1) {
    *retptr0 = 0;
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_clock_time_get(int32_t, int64_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_close(int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_fdstat_get(int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_fdstat_set_flags(int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_prestat_get(int32_t, int32_t) {
    return __WASI_ERRNO_BADF;
}

int32_t __imported_wasi_snapshot_preview1_fd_prestat_dir_name(int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_read(int32_t, int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_seek(int32_t, int64_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_write(int32_t, int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_NOTCAPABLE;
}

int32_t __imported_wasi_snapshot_preview1_path_filestat_get(int32_t, int32_t, int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_path_open(int32_t, int32_t, int32_t, int32_t, int32_t, int64_t, int64_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_poll_oneoff(int32_t, int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

_Noreturn void __imported_wasi_snapshot_preview1_proc_exit(int32_t) { }

int32_t __imported_wasi_snapshot_preview1_random_get(int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}
