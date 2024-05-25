CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -Wextra -O2

TARGET = writer
SRCS = writer.c
OBJS = $(SRCS:.c=.o)
.PHONY: all
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	rm -f $(TARGET) $(OBJS)


.PHONY: filerresult
fileresult: $(TARGET)
	mkdir -p assignments/assignment2
	file $(TARGET) > assignments/assignment2/fileresult.txt
