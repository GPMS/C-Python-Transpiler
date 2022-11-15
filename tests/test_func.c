#include <stdio.h>

int PrintSum(int a, int b)
{
    int sum = a + b;
    printf("Sum is %d\n", sum);
}

int main()
{
    PrintSum(10, 5);
}