#include <wasi/api.h>
#include <sys/types.h>
#include <errno.h>
#include <stdio.h>

// wasi_snapshot_preview1_environ_get
// wasi_snapshot_preview1_environ_sizes_get
char *getenv(const char *) {
    return 0;
}

// wasi_snapshot_preview1_clock_time_get
time_t time(time_t *tloc) {
    return 0;
}

// wasi_snapshot_preview1_clock_time_get
int clock_gettime(clockid_t clock_id, struct timespec *tp) {
    if (tp != NULL) {
        tp->tv_sec = 0;
        tp->tv_nsec = 0;
    }

    return 0;
}

// wasi_snapshot_preview1_clock_time_get
int gettimeofday(struct timeval *restrict tp, void *tz) {
    if (tp != NULL) {
        tp->tv_sec = 0;
        tp->tv_usec = 0;
    }

    return 0;
}

// wasi_snapshot_preview1_fd_pwrite
ssize_t pwritev(int fildes, const struct iovec *iov, int iovcnt, off_t offset) {
    return __WASI_ERRNO_BADF;
}

#if _FORTIFY_SOURCE > 0
int32_t __imported_wasi_snapshot_preview1_fd_close(int32_t) {
    return __WASI_ERRNO_SUCCESS;
}
#else
// wasi_snapshot_preview1_fd_close
int close(int fd) {
    return 0;
}
#endif

int32_t __imported_wasi_snapshot_preview1_fd_fdstat_get(int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_fdstat_set_flags(int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

int32_t __imported_wasi_snapshot_preview1_fd_filestat_get(int32_t, int32_t) {
    return __WASI_ERRNO_BADF;
}

int32_t __imported_wasi_snapshot_preview1_fd_prestat_get(int32_t, int32_t) {
    return __WASI_ERRNO_BADF;
}

int32_t __imported_wasi_snapshot_preview1_fd_prestat_dir_name(int32_t, int32_t, int32_t) {
    return __WASI_ERRNO_SUCCESS;
}

// wasi_snapshot_preview1_fd_read
ssize_t read(int fildes, void *buf, size_t nbyte) {
    return 0;
}

// wasi_snapshot_preview1_fd_read
ssize_t readv(int fildes, const struct iovec *iov, int iovcnt) {
    return 0;
}

// wasi_snapshot_preview1_fd_seek
off_t lseek(int fildes, off_t offset, int whence) {
    return 0;
}

// wasi_snapshot_preview1_fd_seek
off_t __stdio_seek(FILE *f, off_t off, int whence) {
	return 0;
}

// wasi_snapshot_preview1_fd_write
ssize_t write(int fildes, const void *buf, size_t nbyte) {
    errno = __WASI_ERRNO_BADF;
    return -1;
}

// wasi_snapshot_preview1_fd_write
ssize_t writev(int fildes, const struct iovec *iov, int iovcnt) {
    errno = __WASI_ERRNO_BADF;
    return -1;
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
