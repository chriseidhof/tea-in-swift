# The Elm Architecture in Swift

This project is a port of [The Elm Architecture](https://guide.elm-lang.org/architecture/) to Swift.

This is sample code, and not at all production-ready. It's a proof-of-concept, it seems to work well and I don't think there are major roadblocks (except adding all of UIKit to the virtual views layer).

Open the workspace, and look at the playgrounds. It shows some examples. (Even though the playgrounds currently don't seem to run).

Then go to AppDelegate, and run one of the three apps (uncomment the right lines to run one of them).

This is part of an upcoming project I'm working on, and I am planning to write up documentation for usage and implementation (at some point).

There are three sample apps:

- [Empty app](https://github.com/chriseidhof/tea-in-swift/blob/master/Todos/TodosFramework/EmptyApp.swift)
- [GIF loading](https://github.com/chriseidhof/tea-in-swift/blob/master/Todos/TodosFramework/GifApp.swift)
- [Todo List](https://github.com/chriseidhof/tea-in-swift/blob/master/Todos/TodosFramework/TodosApp.swift)


For more Elm-like frameworks in Swift, see Yasuhiro Inami's [excellent list](https://gist.github.com/inamiy/bd257c60e670de8a144b1f97a07bacec).

Enjoy!

---

Notes: 

- If you come from a functional language such as Elm or Haskell, you might be put off by the fact that `send` is marked as `mutating`. Don't be fooled: it behaves very similar to Elm/Haskell. You still have value semantics, and you can still have a time-traveling debugger. See [structs and mutation](http://chris.eidhof.nl/post/structs-and-mutation-in-swift/) or [undo history](http://chris.eidhof.nl/post/undo-history-in-swift/) for some more info on that.
