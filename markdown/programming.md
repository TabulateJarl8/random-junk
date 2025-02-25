# Typed Python

| Category                    | Rating | Notes                                                                                    |
| --------------------------- | ------ | ---------------------------------------------------------------------------------------- |
| Learning Curve              | 5/5    |                                                                                          |
| Ability to Prototype        | 5/5    |                                                                                          |
| Refactoring/Maintainability | 3/5    |                                                                                          |
| Language Tooling            | 4/5    | Basedpyright is a nice LSP and things like poetry are good                               |
| Syntax Clarity/Readability  | 4/5    | Python's ability to have terrible one liners with list comps is not a blessing sometimes |
| Specificity (use case)      | 5/5    |                                                                                          |
| Portability/Distribution    | 2/5    | Things like pyinstaller and cibuildwheel help a little bit, but it's still awful         |
| Safety                      | 2/5    |                                                                                          |
| Expressiveness\*            | 4/5    | Missing things like iterator methods, but overall very concise                           |
| Meta-Programming            | 2/5    | Decorators are neat but missing a macro system                                           |

Total Score: 36/50

# Rust

| Category                    | Rating                     | Notes                                                                  |
| --------------------------- | -------------------------- | ---------------------------------------------------------------------- |
| Learning Curve              | 3/5 <!--TODO: maybe a 2--> | Not the most difficult, but not the most easy                          |
| Ability to Prototype        | 2/5                        | Have some useful things like `.unwrap()` but overall pretty cumbersome |
| Refactoring/Maintainability | 5/5                        |                                                                        |
| Language Tooling            | 5/5                        | Clippy, rust-analyzer, cargo, rustdoc, etc.                            |
| Syntax Clarity/Readability  | 3/5                        | Things like lifetimes and generics can be confusing to read            |
| Specificity (use case)      | 4/5                        | Lacking really good support for some areas such as GUI programming     |
| Portability/Distribution    | 4/5                        | Sometimes cross-compiling is a pain, but theres things like `cross`    |
| Safety                      | 5/5                        |                                                                        |
| Expressiveness\*            | 5/5                        |                                                                        |
| Meta-Programming            | 4/5                        | Macros (especially proc macros) are very powerful                      |

Total Score: 40/50

# JavaScript

| Category                    | Rating | Notes                                  |
| --------------------------- | ------ | -------------------------------------- |
| Learning Curve              | 4/5    | Some quirks                            |
| Ability to Prototype        | 5/5    |                                        |
| Refactoring/Maintainability | 2/5    | Maybe the LSP can help you             |
| Language Tooling            | 5/5    | Yummy things like biome, vite, etc     |
| Syntax Clarity/Readability  | 4/5    | Yay iterator chaining                  |
| Specificity (use case)      | 4/5    | Electron, node, frontend               |
| Portability/Distribution    | 4/5    | Nice things like webpack help          |
| Safety                      | 1/5    |                                        |
| Expressiveness\*            | 2/5    | Usually not very pretty if its concise |
| Meta-Programming            | 1/5    |                                        |

Total Score: 32/50

# TypeScript

| Category                    | Rating | Notes                                                                 |
| --------------------------- | ------ | --------------------------------------------------------------------- |
| Learning Curve              | 3/5    | JavaScript with types                                                 |
| Ability to Prototype        | 4/5    | JavaScript--                                                          |
| Refactoring/Maintainability | 4/5    | YAY TYPES                                                             |
| Language Tooling            | 5/5    |                                                                       |
| Syntax Clarity/Readability  | 4/5    | [Except in some cases](https://stackoverflow.com/a/73663236/11591238) |
| Specificity (use case)      | 4/5    |                                                                       |
| Portability/Distribution    | 4/5    |                                                                       |
| Safety                      | 3/5    | JavaScript with types                                                 |
| Expressiveness\*            | 2/5    |                                                                       |
| Meta-Programming            | 2/5    |                                                                       |

Total Score: 35/50

# C

| Category                    | Rating | Notes                                                          |
| --------------------------- | ------ | -------------------------------------------------------------- |
| Learning Curve              | 2/5    | Simple but complex                                             |
| Ability to Prototype        | 2/5    | Difficult to prototype _correct_ code                          |
| Refactoring/Maintainability | 3/5    | Not the absolute worst but there's a lot the compiler can miss |
| Language Tooling            | 3/5    | clangd, clang-format, clang-check                              |
| Syntax Clarity/Readability  | 4/5    | Very readable except for when you get pointers involved        |
| Specificity (use case)      | 4/5    | Just please dont do AI in C                                    |
| Portability/Distribution    | 3/5    | cross-compiling is a pain but at least it's not interpreted    |
| Safety                      | 1/5    | You've got the type system and thats about it                  |
| Expressiveness\*            | 4/5    | Can we very concise and elegant                                |
| Meta-Programming            | 3/5    |                                                                |

Total Score: 29/50

# C++

| Category                    | Rating | Notes                                               |
| --------------------------- | ------ | --------------------------------------------------- |
| Learning Curve              | 2/5    | There is way too much the language is trying to be  |
| Ability to Prototype        | 3/5    | Probably easier than C, but still pretty cumbersome |
| Refactoring/Maintainability | 3/5    | Can get very messy but not the worst                |
| Language Tooling            | 3/5    | Clang, CMake, vcpkg, etc                            |
| Syntax Clarity/Readability  | 1/5    | Absolutely horrendous to read                       |
| Specificity (use case)      | 5/5    |                                                     |
| Portability/Distribution    | 3/5    | Similar to C                                        |
| Safety                      | 2/5    | C++;                                                |
| Expressiveness\*            | 3/5    | Inline asm, templating, etc.                        |
| Meta-Programming            | 2/5    | Templating can be very, very difficult              |

Total Score: 27/50

\*Expressiveness means how much work can be done with minimal and elegant code
