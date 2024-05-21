#include <stdio.h>

#ifdef FOO
void foo()
{
    printf("FOO is defined\n");
}
#endif

#ifndef BAR
void bar()
{
    printf("BAR is not defined\n");
}
#endif

int main()
{
#ifdef FOO
    foo();
#endif

#ifndef BAR
    bar();
#endif

    return 0;
}
