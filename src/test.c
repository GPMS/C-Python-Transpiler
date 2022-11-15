#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>

#include <dirent.h>


bool CompareFiles(const char* filename1, const char* filename2)
{
    FILE* f1 = fopen(filename1, "r");
    FILE* f2 = fopen(filename2, "r");

    if (!f1 || !f2)
    {
        fprintf(stderr, "ERROR: couldn't read %s and/or %s\n", filename1, filename2);
        return false;
    }

    int c1;
    bool result = true;
    while ((c1 = fgetc(f1)) != EOF)
    {
        int c2 = fgetc(f2);

        if (c2 == EOF)
        {
            result = false;
            break;
        }

        if (c1 != c2)
        {
            result = false;
            break;
        }
    }
    fclose(f1);
    fclose(f2);
    return result;
}

bool Transpile(const char* input)
{
    pid_t my_pid = fork();
    if (my_pid == 0)
    {
        if (execl("./cmp", "./cmp", input, NULL) == -1)
        {
                perror("child process execve failed: ");
                return false;
        }
    }
    else
    {
        int timeout = 1000;
        int     status;
        while (waitpid(my_pid , &status , WNOHANG) == 0)
        {
            if ( --timeout < 0 ) {
                perror("timeout");
                return false;
            }
            sleep(1);
        }
        return true;
    }
}

bool RunTests(const char* path)
{
    int failedCount = 0;

    DIR *d;
    struct dirent *dir;
    d = opendir(path);
    if (d)
    {
        while ((dir = readdir(d)) != NULL)
        {
            char* fileName = strdup(dir->d_name);
            size_t nameLen = strlen(fileName);

            if (fileName[nameLen-1] == 'c')
            {
                char filePath[256];
                snprintf(filePath, sizeof(filePath), "%s/%s", path, fileName);
                if (!Transpile(filePath))
                {
                    fprintf(stderr, "Failed to transpile %s\n", fileName);
                    failedCount++;
                }
                else
                {
                    fileName[nameLen-2] = '\0';
                    char* testName = fileName;
                    const char* generatedPyFile = "output/output.py";
                    char testPyFile[256];
                    snprintf(testPyFile, sizeof(testPyFile), "%s/%s.py", path, testName);
                    if (!CompareFiles(generatedPyFile, testPyFile))
                    {
                        fprintf(stderr, "%s: FAILED\n", fileName);
                        failedCount++;
                    }
                    else
                    {
                        fprintf(stderr, "%s: PASSED\n", fileName);
                    }
                }
            }

            free(fileName);
        }
        closedir(d);
    }
    return failedCount;
}

int main()
{
    int failedCount = RunTests("./tests");
    if (failedCount == 0)
    {
        fprintf(stderr, "All tests passed\n");
        return 0;
    }
    else
    {
        fprintf(stderr, "%d tests failed\n", failedCount);
        return 1;
    }
}