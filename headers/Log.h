#define LOGLEVEL_VERBOSE     10
#define LOGLEVEL_INFO        6
#define LOGLEVEL_WARNING     4
#define LOGLEVEL_DISABLED    1

#define NSLog(fmt, ...) NSLog((@"[dig3st] " fmt), ##__VA_ARGS__)