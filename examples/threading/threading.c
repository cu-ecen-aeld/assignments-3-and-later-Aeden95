#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    usleep(thread_func_args->wait_to_obtain_ms * 1000);
    if (pthread_mutex_lock(thread_func_args->mutex) != 0) {
        ERROR_LOG("Failed to lock mutex\n");
        return NULL;
    }
    DEBUG_LOG("Mutex locked\n");
    usleep(thread_func_args->wait_to_release_ms * 1000);
    if (pthread_mutex_unlock(thread_func_args->mutex) != 0) {
        ERROR_LOG("Failed to unlock mutex\n");
        return NULL;
    }
    DEBUG_LOG("Mutex unlocked\n");

    thread_func_args->thread_complete_success = true;
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    struct thread_data* tdata = (struct thread_data*)malloc(sizeof(struct thread_data));
    if (tdata == NULL) {
        ERROR_LOG("Failed to allocate memory for thread_data\n");
        return false;
    }

    tdata->mutex = mutex;
    tdata->wait_to_obtain_ms = wait_to_obtain_ms;
    tdata->wait_to_release_ms = wait_to_release_ms;
    tdata->thread_complete_success = false; 

    if (pthread_create(thread, NULL, threadfunc, (void*)tdata) != 0) {
        ERROR_LOG("Failed to create thread\n");
        free(tdata);
        return false;
    }

    return true;
}

