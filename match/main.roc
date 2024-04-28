app "match"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.0/oKWkaruh2zXxin_xfsYsCJobH1tO8_JvNkFzDwwzNUQ.tar.br" }
    imports [
        pf.Stdout,
        pf.Task.{ Task },
        Literals,
        Wildcard,
        StartOfString,
        EndOfString,
        Repetitions,
    ]
    provides [main] to pf

main : Task {} I32
main =
    Stdout.line "hello world"
