#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>

void usage(const char *progname) {
    fprintf(stderr, "Usage: %s <writefile> <writestr>\n", progname);
}

int main(int argc, char *argv[]) {
    openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

    if (argc != 3) {
        usage(argv[0]);
        syslog(LOG_ERR, "Error: Invalid number of arguments");
        exit(1);
    }

    const char *writefile = argv[1];
    const char *writestr = argv[2];

    FILE *file = fopen(writefile, "w");
    if (file == NULL) {
        syslog(LOG_ERR, "Error: Could not open file %s for writing: %s", writefile, strerror(errno));
        exit(1);
    }

    if (fprintf(file, "%s", writestr) < 0) {
        syslog(LOG_ERR, "Error: Could not write to file %s: %s", writefile, strerror(errno));
        fclose(file);
        exit(1);
    }

    if (fclose(file) != 0) {
        syslog(LOG_ERR, "Error: Could not close file %s: %s", writefile, strerror(errno));
        exit(1);
    }

    syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);
    closelog();

    return 0;
}