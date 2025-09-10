#include <wasi/api.h>

// wasi_snapshot_preview1_environ_get
// wasi_snapshot_preview1_environ_sizes_get
char *getenv(const char *) {
    return 0;
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

int32_t __imported_wasi_snapshot_preview1_fd_filestat_get(int32_t, int32_t) {
    return __WASI_ERRNO_BADF;
}

int32_t __imported_wasi_snapshot_preview1_fd_pread(int32_t, int32_t, int32_t, int64_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_prestat_get(int32_t, int32_t) {
    return __WASI_ERRNO_BADF;
}

int32_t __imported_wasi_snapshot_preview1_fd_prestat_dir_name(int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_pwrite(int32_t, int32_t, int32_t, int64_t, int32_t) {
    return __WASI_ERRNO_BADF;
}

int32_t __imported_wasi_snapshot_preview1_fd_read(int32_t, int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_seek(int32_t, int64_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_write(int32_t, int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_BADF;
}

int32_t __imported_wasi_snapshot_preview1_path_filestat_get(int32_t, int32_t, int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_BADF;
}

int32_t __imported_wasi_snapshot_preview1_path_open(int32_t, int32_t, int32_t, int32_t, int32_t, int64_t, int64_t, int32_t, int32_t) {
    return __WASI_ERRNO_BADF;
}

// wasi_snapshot_preview1_poll_oneoff
int usleep(unsigned long) {
    return 0;
}

// wasi_snapshot_preview1_proc_exit
_Noreturn void _Exit(int) { }

int32_t __imported_wasi_snapshot_preview1_sched_yield() {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_random_get(int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}
