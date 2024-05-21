#!/bin/sh

# Have `FOO` defined. This will define the `foo()` function.
#
# ```c
# void foo()
# {
#     printf("FOO is defined\n");
# }
# ```
#
# But note that because `BAR` is not defined/undefined, the `#ifndef BAR`
# section is left intact.
echo "**************************************************"
echo "Demo 1"
./unifdef -DFOO ./example.c

# Have `FOO` undefined. This will remove the definition of the `foo()` function.
# Again, because `BAR` is not defined/undefined, the `#ifndef BAR` section is
# left untouched.
echo "**************************************************"
echo "Demo 2"
./unifdef -UFOO ./example.c

# Have `FOO` undefined and `BAR` defined. This will remove the definition of
# both functions and leave an empty program.
# #include <stdio.h>
#
# int main()
# {
#     return 0;
# }
echo "**************************************************"
echo "Demo 3"
./unifdef -UFOO -DBAR ./example.c
