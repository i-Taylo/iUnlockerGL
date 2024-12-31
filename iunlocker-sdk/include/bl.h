#ifndef BL_H
#define BL_H

#define CONCAT(x, y) x ## y
#define DOUBLE(x) ((x) << 1)
#define SQUARE(x) ((x) * (x))
#define XOR(a, b) (((a) | (b)) & ~((a) & (b)))
#define ROTATE_LEFT(x, n) (((x) << (n)) | ((x) >> (32 - (n))))
#define ROTATE_RIGHT(x, n) (((x) >> (n)) | ((x) << (32 - (n))))
#define FIB(n) ((n) <= 1 ? (n) : FIB((n) - 1) + FIB((n) - 2))

#define ARCH_CODE_ARM SQUARE(2) * 3 + 1 - DOUBLE(3) // = 10
#define ARCH_CODE_ARM64 ROTATE_LEFT(ARCH_CODE_ARM, 1) // = 20
#define ARCH_CODE_X86 ROTATE_RIGHT(ARCH_CODE_ARM64, 2) ^ 5 // = 15
#define ARCH_CODE_X86_64 XOR(ARCH_CODE_X86, ARCH_CODE_ARM64) // = 35

#define DETECT_ARCH                                         \
    SQUARE(                                                 \
        (__arm__ ? ARCH_CODE_ARM                            \
        : (__aarch64__ ? ARCH_CODE_ARM64                    \
        : (__i686__ ? ARCH_CODE_X86                         \
        : (__x86_64__ ? ARCH_CODE_X86_64                    \
        : -1)))))

#define CHECK_ARCH (DETECT_ARCH == -1 ? "Unknown" : "Valid")

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

#define ARCH_NAME                                \
    (__arm__ ? CONCAT(a, r) "m32"                \
    : (__aarch64__ ? CONCAT(a, r) "m64"          \
    : (__i686__ ? CONCAT(x, 8) "6"               \
    : (__x86_64__ ? CONCAT(x, 8) "6_64"          \
    : "unknown"))))

#define OUTPUT_ARCH_DETAILS \
    STR(Detected Architecture Code: DETECT_ARCH) \
    STR(Architecture Name: ARCH_NAME)

#if DETECT_ARCH == -1
    #error "Architecture detection failed!"
#else
    #warning "Architecture detection succeeded: " ARCH_NAME
#endif

#endif // BL_H
