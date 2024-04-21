app "log-append" packages { 
        cli: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br"
    }
    imports [
        cli.Stdout,
        cli.File,
        cli.Task,
        cli.Path,
        cli.Utc,
    ]
    provides [ main ] to cli

log = \msg, val ->
    path = Path.fromStr "logFile"
    now <- Utc.now |> Task.await
    millis = Utc.toMillisSinceEpoch now
    seconds = Num.round (Num.toFrac millis / Num.toFrac 1000)
    time = Num.toStr seconds
    appendToFile path "$(time) $(msg): $(Inspect.toStr val)\n"

# TODO: figure out type annotation, and its pertinence for this iteration
# appendToFile : Path, Str -> Task {} [FileReadErr Path.Path InternalFile.ReadErr, FileWriteErr Path.Path InternalFile.WriteErr]
appendToFile = \path, msg ->
    newBytes = Str.toUtf8 msg
    existingBytes <- File.readBytes path |> Task.await
    File.writeBytes path (List.concat newBytes existingBytes)

main =
    log "This is a value:"
    Task.onErr
        (log "This is a value:" 42)
        handleErr

handleErr = \err ->
    Stdout.line "We found an error: $(Inspect.toStr err)"
