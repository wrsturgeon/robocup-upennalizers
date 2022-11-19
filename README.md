# UPennalizers

Forked from the original (c. 2019, GitLab); iterative improvements.

## Core Principles
RoboCup is a competition in the formal sense, but above all it's a community, and anyone who's been to a competition can tell you how friendly, helpful, and driven everyone is. Winning a competition means open-sourcing all of your code and sharing it freely. Smaller universities regularly take down larger ones and laugh about it over drinks in a foreign country. It's not about being smarter or more powerful; it's about asking the right questions. It's not about winning; it's about the chase. In sum, it's about the polar opposite of the University of Pennsylvania undergraduate experience, and we strive to keep a community here who are truly fascinated by this stuff and want to work with, learn with, and hang with other people who are, too.

To that end, we propose a few guiding principles for any iteration of this long-standing team, and they are, in order,
1. Encourage people to fall in love with robotics.
   1. Be open to anyone, regardless of major, career interest, or prior competence, without exception.
   2. Value effort, innovation, and contributions over seniority or prior experience.
   3. Actively discourage the hive mind. If a humanities student walks in and asks to join the computer vision team, fist _say yes_, and then fight the urge to teach them the methods we use; instead, tell them the problems we're working on, and embrace an open-ended response. Knowing "the way things are done" is a surefire way to be no better than any other team; if you're all working on the same thing, the entire purpose of RoboCup is out the window. Do something stupid while you can. We're in college with tens of thousands of dollars of equipment to fuck around with; why would you take the easy way out?
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

Two unfortunate facts drive every design decision you're about to read: first, robots overheat very easily, and second, large codebases are difficult to maintain.

### C++
Of the above two facts, C++ is certainly a concession to the former more than the latter, but when used judiciously it's a beautiful and incredibly powerful language.

#### The main idea

C++ inherits almost everything from C. C, for those of you who don't know, is the language your operating system was written in; it allows you to have control over all the shit most people now really don't ever want control over, but as a result you can abuse practically everything about your computer to squeeze the last drops of performance out. For reference, an algorithm in C rewritten word-for-word in Java will be ~3x slower, and in Python ~10-100x slower. This is and will always be the main reason behind the choice, and the numbers are impossible to argue with.

C++ is C with extra features. The main idea is to introduce more flexibility at compile time without any runtime differences; in standardese, it aims for "zero-cost abstractions." But, at the same time, C++ is so old they didn't get everything right the first time; it's "an octopus made by nailing extra legs onto a dog" (Steve Taylor), or, in stronger terms, "C++ is to C as lung cancer is to lung" (The UNIX-Haters Handbook). More quips [here](https://crypto.stanford.edu/~blynn/c/cpp.html). But, all jokes aside, many of—no, scratch that, a small minority of C++ features are useful, safe, and versatile, letting us write better code that can adapt to changing circumstances without requiring a rewrite or stupid function names like `add_8b`, `add_16b`, `add_32b`, etc. The thing C purists _won't_ tell you is that the list of safe, "good" features is pretty universally agreed upon. In the words of ~~God himself~~ Bjarne Stroustrup, "within C++ is a smaller, simpler, safer language struggling to get out," and, to that end, a few recommendations:
- Use newer features whenever they make your code clearer, but never just for the sake of being newer.
- Read the codebase! Familiarize yourself with it before feeling overwhelmed by learning "all of C++," which, trust me, no one knows. Most stuff will make sense by reading it in use, with a few exceptions (like rvalue references (`type&&`), `std::move`, and "global" variables), but those are covered below.
- StackOverflow is great, but, please, check the date and OS on any posts you find. Microsoft's computers are pieces of shit, but their compilers and operating systems are even worse. They're the only reason game developers have to rewrite code for different operating systems: there's one function call for every OS but Windows, and one entirely different call for Windows. Their MSVC compiler is also notoriously horrible and so fucked by this point that the standards committee has rejected proposals because they wouldn't work with MSVC, although they'd be trivial to add to any other (open-source!) compiler. Anyway. <\/rant> Regarding the date of posts, a new version of C++ comes out every 3 years, and often these add functionality to cover gaping holes in old ones; oftentimes a clever workaround will be heralded as genius before being replaced by something standardized and readable a few years later. With that said, though, recent answers almost always make use of best practices or have some strongly upvoted comment pointing out that they should've.

In general, never let the language scare you away from jumping in. Team leadership ought to have a competent and passionate leader every year and ensure that years down the line do, too, so write something, submit it, and get feedback!

#### What Makes C++ Different

##### Compilation
This might be familiar to people who've worked with Java before, but once again it's quite different. Java is a corporate product. It's manufactured by Oracle, who controls everything about the software you need to get Java to work. C++ isn't. There's a group of volunteers who specify exactly how it has to work (the Standards Committee) and anyone can write a compiler (if you don't know what that is, read on).

There are, broadly, two kinds of languages: compiled and interpreted. Python, for example, is interpreted: you run an application which reads source code in real time, manually keeps track of all variables as it goes, and tries everything without checking beforehand if it'll work. This is nice if you don't want to plan all the minor details ahead of time, but it's incredibly slow and often leads to trivial errors not presenting themselves until you've already run half the program (like passing a string to an int parameter after already doing all the hard work). Compiled languages like C++, on the other hand, work in two steps: first, a _compiler_ reads your source code and **doesn't** execute it but, instead, translates it from a text file into binary code your computer can understand natively. This was C's original purpose: binary code looks a bit different on every machine, but C extracts structural similarities: now you have one source file for all machines.

The tradeoff, however, is that machines don't do _anything_ to hold your hand through the program. Have a 10-element array and ask for the 11th element? Sure thing. You'll get _something_, but it won't make any sense, and writing to it has a good chance of forcibly terminating the program, if not worse. See some strategies to prevent this kind of stuff in the "Debugging & Exceptions" header below.

##### The Memory Model
Very basically, ordinary variables in C++ are required to actually take up space on your computer, and in general they can't be optimized away (e.g. compiling `int a = 1; int b = 2; return a + b;` will _not_, in general, boil down to just returning 3). This is because the standard guarantees you always know exactly where a variable is in your computer and exactly how much space it's taking up: if you were to optimize the call to return 3, you'd have to prove that there's no possible way any part of the program could ever want to access the size or location of `a` or `b` (so the program could be run _as if_ they had locations), but this is in general too hard for compilers to nitpick and it's a better bet to take steps to avoid temporaries in the first place.

### Offensive Anti-Error Strategies

#### Debugging & Exceptions

The basic idea is that when we're developing, building to debug should be the default, but when we run the code on the robot (especially in a match), any exception will make it crash and fall over, probably both losing us the game and damaging hardware. To this end, release builds are compiled with heavy optimization and two crucial command-line arguments:
- `-DNDEBUG`, which blows `assert` statements (for those who don't speak C, `assert` isn't a function, so when `NDEBUG` is defined, anything inside its parentheses will just be deleted: e.g. `assert(printf...)` won't print anything).
- `-fno-exceptions`, which disables all exceptions (you'll get a compile-time error if any are even possible).

Throw all the exceptions you want in debug builds, but wrap them in `#ifndef NDEBUG ... #endif // NDEBUG` and **make sure they can't happen in-game**. When something goes _fatally_ wrong, use `debug_print(std::cerr, ...); std::terminate();`, which will somewhat gracefully quit the program print in debug builds only (if a release build crashes, rebuild it with debugging and run it again).
