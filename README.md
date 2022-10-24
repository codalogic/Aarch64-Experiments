# Aarch64 Experiments

Experiments with Arm Aarch64 / Arm64 Assembly Code

The intent is to build up some code that will act as an introduction to
Aarch64/Arm64 programming.  Each program will build on the previous program
but each step will be stored in a separate directory so that the
evolution is clear and others can follow the growth of the code.

I run this on a Raspbery Pi 4 running Ubuntu.

I use the GNU assembler: GAS.  To get these tools do:

```bash
sudo apt update
sudo apt upgrade
sudo apt install gcc
```

To more easily build the code I've created a bash file called `aarch64` that contains:

```bash
as -o $1.o $1.s && ld -o $1 $1.o && ./$1
```

(Don't forget to do chmod +x aarch64 to make the bash file executable.)

For example, to build the code in the first example, called `exit`, do:

```bash
pete$ aarch64 exit
```
