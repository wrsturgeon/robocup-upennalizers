# UPennalizers

Welcome in!

This codebase exists as a shared document, the culmination both of hard work by students at the University of Pennsylvania and of the larger RoboCup community, whom we cannot thank enough for these opportunities.

## Core Principles
RoboCup is a competition in the formal sense, but, above all, it's a community. Winning means open-sourcing all of your code and sharing it freely; smaller universities regularly beat larger ones, and the tangible camaraderie and passion show through in each team's work. The League thrives on contributions from people like you. It's not about being smarter or more powerful; it's about asking the right questions. It's not about winning; it's about the chase. It's practically the opposite of the usual University of Pennsylvania undergraduate experience, and as such, we are a community proud to be truly fascinated by this stuff and want to work with, learn with, and hang with people who are as well.

### Some Practical Considerations
Our main goals are, in order,
1. To encourage falling in love with robotics.
   1. The team is open to anyone, regardless of major, career interest, or prior competence, without exception.
   2. We value effort, innovation, and contributions over seniority or prior experience.
   3. We actively discourage the hive mind. If a humanities student walks in and asks to join the computer vision team, say yes, and actively fight the urge to teach them the methods we use; instead, tell them the problems we're working on, and embrace an open-ended response. Knowing "the way things are done" is a surefire way to be no better than any other team; if we're all working on the same thing, the entire purpose of RoboCup is out the window. Do something stupid while you can: we're in college with tens of thousands of dollars of equipment to fuck around with, so why take the easy way out?
2. Write code that takes #1 seriously.
   1. Never write something you don't fully understand.
      1. Please never blindly copy from a tutorial or StackOverflow. Not only does it introduce code from many different philosophies, style guides, and libraries, it also renders you perfectly obsolete. Anyone can copy; instead, understand it and write it yourself. Comment the original source for both attribution and explanation, but strive to write code clean enough that no one needs to read the original. Besides, where's the fun in copying? Own what you make and be proud of it.
   2. Understand—and document—your code well enough to have it run without any exceptions, assertions, bounds checking, or hand-holding of any kind.
      1. The fundamental reality to keep in mind is that these robots overheat. Compared to your laptop, they're like a Nokia to an NVIDIA GPU. Any checks that happen _at runtime_ are complete wastes of time unless they are legitimately undecidable (or, again, complicated enough that they would impede future teams' ability to build on them).
      2. Be as flexible as possible. Work against inevitable human error and assume that literally everything will change.
         1. Don't hard-code anything. If, for example, the size of a struct is now 8 bytes (and you should know because you wrote it), _still_ use `sizeof`. Eventually, someone will change something about it, and everything _else_ will break.
         2. Anything that _can_ be computed at compile time _should_. `sizeof` above is a perfect example. C++ templates are great.
3. Make a great product and be proud of it. There aren't many people in the world who can do this; welcome to the club.

## Original README:

The project began with the University of Pennsylvania RoboCup code base from
the 2011 RoboCup season and continues to evolve into an ever more
generalized and versatile robot software framework.

(Legacy) Documentation:
  The GitHub Wiki hosts the main source of documentation for this project:
    - https://github.com/UPenn-RoboCup/UPennalizers/wiki 

Contact Information:
  UPenn Email:      upennalizers@gmail.com
  UPenn Website:    https://fling.seas.upenn.edu/~robocup/wiki/

## Compiling and Using the Code

New code can be compiled with `./compile [path/to/file] [--release/--debug]`, which creates an executable at `bin/robocup-[file]`. Compile the entire game routine with `./compile start.cpp --release`, which creates `bin/robocup-start`.

When `ssh`'d into a robot, use `nohup bin/robocup-start &` to keep the robot playing when you disconnect. `nohup` tells the process to survive your terminal logout and the ampersand tells the OS to run `robocup-start` in the background; in other words, your robot won't stop it until the GameController says the game is over or you manually lookup the process and kill it with `killall robocup-start`.

Legacy code can be run by `cd`ing to `include/legacy/Player/` and using `./game main`.

## Coding Guidelines for Active Contributors

Two conflicting facts drive pretty much everything below: first, robots overheat very easily, and second, large codebases are difficult to maintain.

### C++
Of the above two facts, C++ is certainly a concession to the former more than the latter, but when used judiciously it's a beautiful and incredibly powerful language.

#### The main idea

C++ inherits almost everything from C. C is the language your operating system was written in, and it's more often than not the language every other language is written in. C allows you to have control over all the shit most people now really don't ever want control over, and with the risk of fucking it up, you get to abuse every nook and cranny of your computer to squeeze out the last drops of performance. For reference, an algorithm in C rewritten word-for-word in Java will be ~3x slower, and in Python ~10-100x slower. This is clearly the driving force behind the choice of a variant of C, and the numbers are difficult to argue with.

C++ is C with extra features, originally designed as a superset of C (so that any valid C program is already valid in C++). These "extra features" were designed to be, in standardese, _zero-cost abstractions_: they (ought to) introduce more flexibility at compile time without sacrificing runtime performance. On the other hand, C++ is one of the oldest languages, and some things only sounded like a great idea back then—yet we're forced to keep those ill-considered features for backward compatibility. C purists have called C++ "an octopus made by nailing extra legs onto a dog" (Steve Taylor), or, in stronger terms, "C++ is to C as lung cancer is to lung" (The UNIX-Haters Handbook) (more quips [here](https://crypto.stanford.edu/~blynn/c/cpp.html)). But, all jokes aside, many—no, scratch that, a _few_ of C++ features are useful, safe, and versatile, letting us write better code that can adapt to changing circumstances without requiring a rewrite or stupid function names like `add_8b`, `add_16b`, `add_32b`, etc. C purists won't tell you is that the list of safe, "good" features is actually fairly agreed upon. In the words of ~~God himself~~ Bjarne Stroustrup, "within C++ is a smaller, simpler, safer language struggling to get out," so here are a few rules of thumb to cut some thorns of C++:
- Read our codebase! Familiarize yourself with it before feeling overwhelmed by learning "all of C++," (which _no one_ knows). Most stuff will make sense by reading it in use, with a few exceptions (like rvalue references (`type&&`), `std::move`, and "global" variables), but those are covered below.
- Use newer features whenever they make your code clearer, but never just for the sake of being newer.
- StackOverflow is great, but please check the date and OS on any posts you find. Microsoft's computers are pieces of shit, but their compilers and operating systems are worse. They're the only reason game developers have to rewrite code for different operating systems: there's one function call for every OS but Windows, and one entirely different call for Windows. Their MSVC compiler is also notoriously horrible and in fact so fucked by this point that the standards committee has rejected proposals because they wouldn't work with MSVC. Anyway, `<\/rant>` regarding the date of posts, a new version of C++ comes out every 3 years, and often these add functionality to cover gaping holes in old ones; oftentimes a clever workaround will be heralded as genius before being replaced by something standardized and readable a few years later. With that said, though, recent answers almost always make use of best practices or have some strongly upvoted comment pointing out that they should've.

Never let the language scare you away from jumping in. Team leadership ought to have a competent and passionate leader every year and ensure that years down the line do, too, so write something, submit it, and get feedback!

#### What Makes C++ Different

##### Compilation
This may be familiar to those of us who've worked with Java, but it's a bit different with C++. Java is a corporate product. It's manufactured by Oracle, who controls everything about the software you need to get Java to work. C++ isn't, and its purpose has always been to run _on your machine directly_ without an intermediary, and—secondarily—to be more easily portable than writing code for every machine. (When you think about it, it's a small marvel that we can write the same source code for our laptops and for the robots, and they just work.) There's a group of volunteers who specify exactly how it has to work (the Standards Committee) and anyone can _implement_ a compiler satisfying the standard; a few open-source groups (notably GNU with `gcc` and LLVM with `clang`) have done a wonderful job. (Microsoft, well, didn't, and won't release their source code, so no one can help them unfuck it.)

If you're familiar with compilation, skip this paragraph, but if not, there are broadly two kinds of languages: compiled and interpreted. Python, for example, is interpreted: you run an application which reads source code in real time, manually keeps track of all variables as it goes, and tries everything without checking beforehand if it'll work. This is nice if you don't want to plan all the minor details ahead of time, but it's incredibly slow and often leads to trivial errors not presenting themselves until you've already run half the program (like passing the wrong type to a function after already doing all the hard work). Why don't they check for these errors ahead of time? They can't, in general, and it's somewhat at odds with their design philosophy to do it part-way. Compiled languages like C++, on the other hand, work in two steps: first, a _compiler_ reads your source code and **doesn't** execute it but, instead, translates it from a text file into binary code your computer can understand natively; your computer can then directly run the compiled file, which has nothing to do with C++ anymore. One main goal of this codebase is to catch as many potential errors as possible at compile time, which C++ makes fairly easy and unobtrusive.

The tradeoff of compiling to machine code is that it can't do _anything_ to hold your hand once the program starts running. Have a 10-element array and ask for the 11th element? Sure thing. You'll get _something_, but it won't make any sense, and writing to it has a good chance of forcibly terminating the program, if not worse. CIS 240 does a great job exploring the details, so I'll spare them here, but please see some RoboCup-specific strategies under "Debugging & Exceptions" below.

##### The Memory Model
There's a fundamental contradiction here: C++ has to work with your processor, but every processor is different. As a result, C++ abstracts away a layer and mandates ("in the Standard") that any _implementation_ of C++ ("compiler") has to have the same user-facing behavior, but it's on them to figure out how to interface with the hardware. This is great for you. 

So what does this standard behavior entail? An oversimplified but acceptable explanation is that ordinary variables in C++ are required to have a known size and location on your hardware while they exist (are in scope). The tradeoff here is that, in general they can't be optimized away (e.g. compiling `int a = 1; int b = 2; return a + b;` will _not_, in general, boil down to just returning 3; otherwise taking the location or size of `a` or `b` would fail). There's a caveat here called the _as-if principle_: if you (the compiler) can prove that there's no possible way any part of the program could ever want to access the size or location of `a` or `b`, then it's fine to optimize, since the program can be run _as if_ `a` and `b` had known locations: they have no effect either way. This sounds difficult to prove, and it is; most compilers just give up past a certain point. Take-home message: _don't use temporaries like_ `a` _and_ `b`. If you want more nuanced details, or to know how to accept values that explicitly _can_ be optimized away, look under `rvalues` below.

### Offensive Anti-Error Strategies

#### Debugging & Exceptions

The basic idea is that when we're developing, building to debug should be the default, but when we run the code on the robot (especially in a match), any exception will make it crash and fall over, probably both losing us the game and damaging hardware. To this end, release builds are compiled with heavy optimization and two crucial command-line arguments:
- `-DNDEBUG`, which defines the macro `NDEBUG` to 1 and thus tells the compiler to skip `assert` statements (and note that anything inside its parentheses will just be deleted: e.g. `assert(printf...)` won't print anything).
- `-fno-exceptions`, which disables all exceptions (you'll get a compile-time error if any are even possible).

Best practices: Throw all the exceptions you want in debug builds, but wrap them in `#ifndef NDEBUG ... #endif // NDEBUG` and **make sure they can't happen in-game**. When something goes _fatally_ wrong, use `debug_print(std::cerr, ...); std::terminate();`, which will somewhat gracefully quit the program print in debug builds only. If a release build crashes (which it _shouldn't_—it's really only for in-game—but shit happens), rebuild it with debugging and run it again to reproduce the error.

### C++ rvalues

Remember above how variables are required to take up space in the computer? That's only true for things you can _assign to_. If you write `x = f()`, `x` is an _lvalue_ (since it's on the **l**eft), and `f()` is an `rvalue` (since it's on the **r**ight). Lvalues stay lvalues, though: in `x = f(); y = x;`, the second use of `x` (on the right-hand side of an equation) is still an lvalue. So we arrive at a better definition of lvalues: _they_ take up assignable space in your computer, and rvalues are everything else.

You may have seen some function parameters (say, of type `T`) that are written `T&&`: the `&&` accepts _rvalues_, so the compiler is free to snatch the memory from the parameter's original source since we're promising it either didn't really exist or we'll never use it again. `std::move` covers the latter case: if you _promise_ you'll never use it again (this is something the compiler is, again, reticent to investigate), you can call `std::move(x)` on an lvalue `x`, which gives the compiler free reign to mutilate `x` beyond recognition to eliminate temporaries (seriously, don't ever use something after you `std::move` it).
