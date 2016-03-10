<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [Makefile](#makefile)
    - [GCC: Compilation Process](#gcc-compilation-process)
    - [Paths](#paths)
        - [include-paths (Compiler search Headers)](#include-paths-compiler-search-headers)
        - [library-paths (Linker search for librarys)](#library-paths-linker-search-for-librarys)
        - [PATH (Executables and Run-time Shared libraries .dll .so)](#path-executables-and-run-time-shared-libraries-dll-so)
        - [View Paths](#view-paths)
    - [GNU Make](#gnu-make)
        - [File Structure](#file-structure)
        - [Syntax](#syntax)
            - [Phony Targets (or Artificial Targets)](#phony-targets-or-artificial-targets)
            - [Variables](#variables)
            - [Virtual Path - VPATH & vpath](#virtual-path---vpath--vpath)
            - [Pattern Rules](#pattern-rules)
            - [Implicit Pattern Rules](#implicit-pattern-rules)

<!-- markdown-toc end -->

# Makefile #

##GCC: Compilation Process ##

![CompilationProcess](./MISC/GCC_CompilationProcess.png)

## Paths ##

### include-paths (Compiler search Headers) ###
  * Command Option: `-I*dir*` 
  * Environment Variable: `CPATH`

### library-paths (Linker search for librarys) ###
  * Command Option: `-L*dir*` 
  * Environment Variable: `LIBRARY_PATH`

    > In addition, you also have to specify the library name. In Unixes, the library libxxx.a is specified via -lxxx option (lowercase letter 'l', without the prefix "lib" and ".a" extension). In Windows, provide the full name such as -lxxx.lib. The linker needs to know both the directories as well as the library names. Hence, two options need to be specified.

### PATH (Executables and Run-time Shared libraries .dll .so) ###

### View Paths ###
  * List Paths: `cpp -v`
  * Compile in verbose mode (-v) & Show -L library-paths and libraries: `gcc -v -o hello.exe hello.c`

## GNU Make ##

> The makefile can be named "makefile", "Makefile" or "GNUMakefile", without file extension.

> The rules are usually organized in such as way the more general rules come first. The overall rule is often name "all", which is the default target for make.

### File Structure ###
A makefile consists of a set of rules. A rule consists of 3 parts: a target, a list of pre-requisites and a command, as follows:
```
target: pre-req-1 pre-req-2 ...
	command
```
When make is asked to evaluate a rule, it begins by finding the files in the prerequisites. If any of the prerequisites has an associated rule, make attempts to update those first.

``` makefile
all: hello.exe

hello.exe: hello.o
	 gcc -o hello.exe hello.o

hello.o: hello.c
	 gcc -c hello.c
     
clean:
	 rm hello.o hello.exe
```
In the above example, the rule "all" has a pre-requisite "hello.exe". make cannot find the file "hello.exe", so it looks for a rule to create it. The rule "hello.exe" has a pre-requisite "hello.o". Again, it does not exist, so make looks for a rule to create it. The rule "hello.o" has a pre-requisite "hello.c". make checks that "hello.c" exists and it is newer than the target (which does not exist). It runs the command "gcc -c hello.c". The rule "hello.exe" then run its command "gcc -o hello.exe hello.o". Finally, the rule "all" does nothing.

### Syntax ###

#### Phony Targets (or Artificial Targets) ####

A target that does not represent a file is called a phony target. For example, the "clean" in the above example, which is just a label for a command. If the target is a file, it will be checked against its pre-requisite for out-of-date-ness. Phony target is always out-of-date and its command will be run. The standard phony targets are: `all, clean, install`.

#### Variables ####

A variable begins with a $ and is enclosed within parentheses (...) or braces {...}. Single character variables do not need the parentheses. For example, `$(CC), $(CC_FLAGS), $@, $^`.

##### Automatic Variables #####

Automatic variables are set by make after a rule is matched. There include:

  * $@: the target filename.
  * $*: the target filename without the file extension.
  * $<: the first prerequisite filename.
  * $^: the filenames of all the prerequisites, separated by spaces, discard duplicates.
  * $+: similar to $^, but includes duplicates.
  * $?: the names of all prerequisites that are newer than the target, separated by spaces.

For example, we can rewrite the earlier makefile as:

``` makefile
all: hello.exe
# $@ matches the target; $< matches the first dependent
hello.exe: hello.o
	gcc -o $@ $<

hello.o: hello.c
	gcc -c $<
     
clean:
	rm hello.o hello.exe
```

 
#### Virtual Path - VPATH & vpath ####

You can use VPATH (uppercase) to specify the directory to search for dependencies and target files. For example,

``` makefile
# Search for depen
dencies and targets from "src" and "include" directories
# The directories are separated by space
VPATH = src include
```

You can also use vpath (lowercase) to be more precise about the file type and its search directory. For example,

``` makefile
# Search for .c 
files in "src" directory; .h files in "include" directory
# The pattern matching character '%' matches filename without the extension
vpath %.c src
vpath %.h include
```

#### Pattern Rules ####

A pattern rule, which uses pattern matching character '%' as the filename, can be applied to create a target, if there is no explicit rule. For example,

``` makefile
# Applicable for create .o object file.
# '%' matches filename.
# $< is the first pre-requisite
# $(COMPILE.c) consists of compiler name and compiler options
# $(OUTPUT_OPTIONS) could be -o $@
%.o: %.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<
 
# Applicable for create executable (without extension) from object .o object file
# $^ matches all the pre-requisites (no duplicates)
%: %.o
$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@
```


#### Implicit Pattern Rules ####

Make comes with a huge set of implicit pattern rules. You can list all the rule via --print-data-base option.

#### Dependency Rules ####

Dependency Rules are rules without any command. It indicate that if any file to the right of the colon changes, the target to the left of the colon should be considered out-of-date. The commands for making an out-of-date target up-to-date may be found elsewhere (in this case, by the Pattern Rule above). Dependency Rules are often used to capture header file dependencies.

``` makefile
Main.o : Main.h Test1.h Test2.h
Test1.o : Test1.h Test2.h
Test2.o : Test2.h
```

#### 2.3 A Sample Makefile ####

This sample makefile is extracted from Eclipse's "C/C++ Development Guide -Makefile".

``` makefile
# A sample Makefile
# This Makefile demonstrates and explains 
# Make Macros, Macro Expansions,
# Rules, Targets, Dependencies, Commands, Goals
# Artificial Targets, Pattern Rule, Dependency Rule.

# Comments start with a # and go to the end of the line.

# Here is a simple Make Macro.
LINK_TARGET = test_me.exe

# Here is a Make Macro that uses the backslash to extend to multiple lines.
OBJS =  \
 Test1.o \
 Test2.o \
 Main.o

# Here is a Make Macro defined by two Macro Expansions.
# A Macro Expansion may be treated as a textual replacement of the Make Macro.
# Macro Expansions are introduced with $ and enclosed in (parentheses).
REBUILDABLES = $(OBJS) $(LINK_TARGET)

# Here is a simple Rule (used for "cleaning" your build environment).
# It has a Target named "clean" (left of the colon ":" on the first line),
# no Dependencies (right of the colon),
# and two Commands (indented by tabs on the lines that follow).
# The space before the colon is not required but added here for clarity.
clean : 
  rm -f $(REBUILDABLES)
  echo Clean done

# There are two standard Targets your Makefile should probably have:
# "all" and "clean", because they are often command-line Goals.
# Also, these are both typically Artificial Targets, because they don't typically
# correspond to real files named "all" or "clean".  

# The rule for "all" is used to incrementally build your system.
# It does this by expressing a dependency on the results of that system,
# which in turn have their own rules and dependencies.
all : $(LINK_TARGET)
  echo All done

# There is no required order to the list of rules as they appear in the Makefile.
# Make will build its own dependency tree and only execute each rule only once
# its dependencies' rules have been executed successfully.

# Here is a Rule that uses some built-in Make Macros in its command:
# $@ expands to the rule's target, in this case "test_me.exe".
# $^ expands to the rule's dependencies, in this case the three files
# main.o, test1.o, and  test2.o.
$(LINK_TARGET) : $(OBJS)
  g++ -g -o $@ $^

# Here is a Pattern Rule, often used for compile-line.
# It says how to create a file with a .o suffix, given a file with a .cpp suffix.
# The rule's command uses some built-in Make Macros:
# $@ for the pattern-matched target
# $< for the pattern-matched dependency
%.o : %.cpp
  g++ -g -o $@ -c $<

# These are Dependency Rules, which are rules without any command.
# Dependency Rules indicate that if any file to the right of the colon changes,
# the target to the left of the colon should be considered out-of-date.
# The commands for making an out-of-date target up-to-date may be found elsewhere
# (in this case, by the Pattern Rule above).
# Dependency Rules are often used to capture header file dependencies.
Main.o : Main.h Test1.h Test2.h
Test1.o : Test1.h Test2.h
Test2.o : Test2.h

# Alternatively to manually capturing dependencies, several automated
# dependency generators exist.  Here is one possibility (commented out)...
# %.dep : %.cpp
#   g++ -M $(FLAGS) $< > $@
# include $(OBJS:.o=.dep)
```
