app "diff"
    packages {
        cli: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br",
    }
    imports [
        cli.Stdout,
        cli.Stderr,
        cli.Arg,
        cli.Task.{ Task, await },
        cli.File,
        cli.Path,
        Lcs.{ diffFormat },
    ]
    provides [main] to cli

# TODO: Docstring.
# TODO: Update to validateArgs : List Str -> Result List Str [InvalidArgs]
#validateArgs : List Str -> List Str
#validateArgs = \args -> args

ErrorMsg : Str

readLines : Str -> Task (List Str) ErrorMsg
readLines = \fileName ->
    filePath = Path.fromStr fileName
    File.readUtf8 filePath
    |> Task.attempt \result ->
        when result is
            Ok content -> Task.ok (Str.split content "\n")
            Err err ->
                msg =
                    when err is
                        FileReadErr _ _ -> "Error reading file $(fileName)"
                        _ -> "Unexpected error occurred while attempting to read file $(fileName)"

                Task.err msg

# TODO: Better error messages.
main : Task {} I32
main =
    Task.attempt (Arg.list) \argList ->
        when argList is
            Ok al ->
                # TODO: Validate args instead of filtering out only the 2nd and the 3rd one.
                args = al |> List.dropFirst 1 |> List.takeFirst 2

                fileName1 =
                    when List.get args 0 is
                        Ok fname -> fname
                        Err OutOfBounds -> crash "TODO fname1 arg ($(Str.joinWith args ", "))"

                fileName2 =
                    when List.get args 1 is
                        Ok fname -> fname
                        Err OutOfBounds -> crash "TODO fname2 arg ($(Str.joinWith args ", "))"

                Task.attempt (readLines fileName1) \resultFileName1 ->
                    when resultFileName1 is
                        Ok lines1 ->
                            Task.attempt (readLines fileName2) \resultFileName2 ->
                                when resultFileName2 is
                                    Ok lines2 ->
                                        {} <- Stdout.line (Str.joinWith (diffFormat { colorize: Bool.true } lines1 lines2) "\n") |> await
                                        Task.ok {}

                                    Err msg ->
                                        {} <- Stderr.line msg |> await
                                        Task.err 1

                        Err msg ->
                            {} <- Stderr.line msg |> await
                            Task.err 1

            Err _ ->
                {} <- Stderr.line "Unexpected error occurred when attempting to read the command-line arguments" |> await
                Task.err 1
