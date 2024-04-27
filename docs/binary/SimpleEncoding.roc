interface SimpleEncoding
    exposes [
        SimpleEncoding,
        simpleEncoding,
    ]
    imports []

simpleEncoding = @SimpleEncoding {}

SimpleEncoding := {}
    implements [
        EncoderFormatting {
            u8: encodeU8,
            u16: encodeU16,
            u32: encodeU32,
            u64: encodeU64,
            u128: encodeU128,
            i8: encodeI8,
            i16: encodeI16,
            i32: encodeI32,
            i64: encodeI64,
            i128: encodeI128,
            f32: encodeF32,
            f64: encodeF64,
            dec: encodeDec,
            bool: encodeBool,
            string: encodeString,
            list: encodeList,
            record: encodeRecord,
            tuple: encodeTuple,
            tag: encodeTag,
        },
        DecoderFormatting {
            u8: decodeU8,
            u16: decodeU16,
            u32: decodeU32,
            u64: decodeU64,
            u128: decodeU128,
            i8: decodeI8,
            i16: decodeI16,
            i32: decodeI32,
            i64: decodeI64,
            i128: decodeI128,
            f32: decodeF32,
            f64: decodeF64,
            dec: decodeDec,
            bool: decodeBool,
            string: decodeString,
            list: decodeList,
            record: decodeRecord,
            tuple: decodeTuple,
        },
    ]

encodeU8 : U8 -> Encoder SimpleEncoding
encodeU8 = \num ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        List.append bytes num

encodeU16 : U16 -> Encoder SimpleEncoding
encodeU16 = \num ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        List.reserve bytes 2
        |> List.append (Num.toU8 num)
        |> List.append (Num.shiftRightBy num 8 |> Num.toU8)

encodeU32 : U32 -> Encoder SimpleEncoding
encodeU32 = \num ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        List.reserve bytes 4
        |> List.append (Num.toU8 num)
        |> List.append (Num.shiftRightBy num 8 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 16 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 24 |> Num.toU8)

encodeU64 : U64 -> Encoder SimpleEncoding
encodeU64 = \num ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        List.reserve bytes 8
        |> List.append (Num.toU8 num)
        |> List.append (Num.shiftRightBy num 8 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 16 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 24 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 32 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 40 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 48 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 56 |> Num.toU8)

encodeU128 : U128 -> Encoder SimpleEncoding
encodeU128 = \num ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        List.reserve bytes 8
        |> List.append (Num.toU8 num)
        |> List.append (Num.shiftRightBy num 8 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 16 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 24 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 32 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 40 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 48 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 56 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 64 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 72 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 80 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 88 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 96 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 104 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 112 |> Num.toU8)
        |> List.append (Num.shiftRightBy num 120 |> Num.toU8)

encodeI8 : I8 -> Encoder SimpleEncoding
encodeI8 = \num ->
    Num.toU8 num |> encodeU8

encodeI16 : I16 -> Encoder SimpleEncoding
encodeI16 = \num ->
    Num.toU16 num |> encodeU16

encodeI32 : I32 -> Encoder SimpleEncoding
encodeI32 = \num ->
    Num.toU32 num |> encodeU32

encodeI64 : I64 -> Encoder SimpleEncoding
encodeI64 = \num ->
    Num.toU64 num |> encodeU64

encodeI128 : I128 -> Encoder SimpleEncoding
encodeI128 = \num ->
    Num.toU128 num |> encodeU128

encodeF32 : F32 -> Encoder SimpleEncoding
encodeF32 = \num ->
    f32ToU32 num |> encodeU32

f32ToU32 = \num ->
    parts =
        num
        |> Num.f32ToParts

    shiftedExponent =
        parts.exponent
        |> Num.toU32
        |> Num.shiftLeftBy 23

    shiftedSign = if parts.sign then 0x80000000 else 0

    parts.fraction
    |> Num.bitwiseOr shiftedExponent
    |> Num.bitwiseOr shiftedSign

encodeF64 : F64 -> Encoder SimpleEncoding
encodeF64 = \num ->
    f64ToU64 num |> encodeU64

f64ToU64 = \num ->
    parts =
        num
        |> Num.f64ToParts

    shiftedExponent =
        parts.exponent
        |> Num.toU64
        |> Num.shiftLeftBy 52

    shiftedSign = if parts.sign then 0x8000000000000000 else 0

    parts.fraction
    |> Num.bitwiseOr shiftedExponent
    |> Num.bitwiseOr shiftedSign

encodeDec : Dec -> Encoder SimpleEncoding
encodeDec = \num ->
    Num.withoutDecimalPoint num |> encodeI128

encodeBool : Bool -> Encoder SimpleEncoding
encodeBool = \b ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        if b then
            List.append bytes 1
        else
            List.append bytes 0

encodeString : Str -> Encoder SimpleEncoding
encodeString = \str ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        List.concat bytes (Str.toUtf8 str) |> List.append 0

encodeList : List elem, (elem -> Encoder SimpleEncoding) -> Encoder SimpleEncoding
encodeList = \lst, elemEncoder ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        bytesWithLength = Encode.appendWith bytes (List.len lst |> encodeU64) (@SimpleEncoding {})
        List.walk lst bytesWithLength (\b, elem -> Encode.appendWith b (elemEncoder elem) (@SimpleEncoding {}))

encodeRecord : List
        {
            key : Str,
            value : Encoder SimpleEncoding,
        }
    -> Encoder SimpleEncoding
encodeRecord = \lst ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        bytesWithLength = Encode.appendWith bytes (List.len lst |> encodeU64) (@SimpleEncoding {})
        List.walk
            lst
            bytesWithLength
            (\b, elem ->
                Encode.appendWith b (elem.key |> encodeString) (@SimpleEncoding {})
                |> Encode.appendWith elem.value (@SimpleEncoding {})
            )

encodeTuple : List (Encoder SimpleEncoding) -> Encoder SimpleEncoding
encodeTuple = \lst ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        List.walk lst bytes (\b, elem -> Encode.appendWith b elem (@SimpleEncoding {}))

encodeTag : Str, List (Encoder SimpleEncoding) -> Encoder SimpleEncoding
encodeTag = \name, lst ->
    Encode.custom \bytes, @SimpleEncoding {} ->
        if List.len lst > 0 then
            List.walk lst bytes (\b, elem -> Encode.appendWith b elem (@SimpleEncoding {}))
        else
            bytes

decodeU8 = Decode.custom \bytes, @SimpleEncoding {} ->
    { result: List.get bytes 0 |> Result.mapErr \_ -> TooShort, rest: List.dropFirst bytes 1 }

asU16 = \(b1, b2) ->
    Num.toU16 b2
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU16 b1)

decodeU16 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        when bytes is
            [b1, b2, ..] -> { result: Ok (asU16 (b1, b2)), rest: List.dropFirst bytes 2 }
            _ -> { result: Err TooShort, rest: bytes }

asU32 = \(b1, b2, b3, b4) ->
    Num.toU32 b4
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU32 b3)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU32 b2)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU32 b1)

decodeU32 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        when bytes is
            [b1, b2, b3, b4, ..] -> { result: Ok (asU32 (b1, b2, b3, b4)), rest: List.dropFirst bytes 4 }
            _ -> { result: Err TooShort, rest: bytes }

decodeU64 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        when bytes is
            [b1, b2, b3, b4, b5, b6, b7, b8, ..] ->
                { result: Ok (asU64 (b1, b2, b3, b4, b5, b6, b7, b8)), rest: List.dropFirst bytes 8 }

            _ -> { result: Err TooShort, rest: bytes }

asU64 = \(b1, b2, b3, b4, b5, b6, b7, b8) ->
    Num.toU64 b8
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU64 b7)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU64 b6)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU64 b5)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU64 b4)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU64 b3)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU64 b2)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU64 b1)

decodeU128 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        when bytes is
            [b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, ..] ->
                { result: Ok (asU128 (b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16)), rest: List.dropFirst bytes 16 }

            _ -> { result: Err TooShort, rest: bytes }

asU128 = \(b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16) ->
    Num.toU128 b16
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b15)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b14)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b13)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b12)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b11)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b10)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b9)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b8)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b7)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b6)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b5)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b4)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b3)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b2)
    |> Num.shiftLeftBy 8
    |> Num.bitwiseOr (Num.toU128 b1)

decodeI8 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        Decode.decodeWith bytes decodeU8 simpleEncoding |> Decode.mapResult Num.toI8

decodeI16 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        Decode.decodeWith bytes decodeU16 simpleEncoding |> Decode.mapResult Num.toI16

decodeI32 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        Decode.decodeWith bytes decodeU32 simpleEncoding |> Decode.mapResult Num.toI32

decodeI64 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        Decode.decodeWith bytes decodeU64 simpleEncoding |> Decode.mapResult Num.toI64

decodeI128 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        Decode.decodeWith bytes decodeU128 simpleEncoding |> Decode.mapResult Num.toI128

decodeF32 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        Decode.decodeWith bytes decodeU32 simpleEncoding |> Decode.mapResult u32ToF32

u32ToF32 = \num ->
    parts = {
        sign: Num.bitwiseAnd num 0x80000000 != 0,
        exponent: Num.shiftRightBy (Num.bitwiseAnd num 0x7F800000) 23 |> Num.toU8,
        fraction: Num.bitwiseAnd num 0x007FFFFF,
    }

    Num.f32FromParts parts

decodeF64 = Decode.custom
    \bytes, @SimpleEncoding {} ->
        Decode.decodeWith bytes decodeU64 simpleEncoding |> Decode.mapResult u64ToF64

u64ToF64 = \num ->
    parts = {
        sign: Num.bitwiseAnd num 0x8000000000000000 != 0,
        exponent: Num.shiftRightBy (Num.bitwiseAnd num 0x7FF0000000000000) 52 |> Num.toU16,
        fraction: Num.bitwiseAnd num 0x000FFFFFFFFFFFFF,
    }

    Num.f64FromParts parts

decodeDec = Decode.custom
    \bytes, @SimpleEncoding {} ->
        Decode.decodeWith bytes decodeI128 simpleEncoding |> Decode.mapResult Num.withDecimalPoint

decodeBool = Decode.custom
    \bytes, @SimpleEncoding {} ->
        Decode.decodeWith bytes decodeU8 simpleEncoding |> Decode.mapResult \num -> num != 0

decodeString = Decode.custom
    \bytes, @SimpleEncoding {} ->
        when List.splitFirst bytes 0 is
            Ok { before, after } ->
                { result: Str.fromUtf8 before |> Result.mapErr \_ -> TooShort, rest: after }

            Err _ -> { result: Err TooShort, rest: bytes }

decodeList : Decoder elem SimpleEncoding -> Decoder (List elem) SimpleEncoding
decodeList = \elemDecoder -> Decode.custom \initialBytes, @SimpleEncoding {} ->
        decodeListHelper = \bytes, length, lst ->
            if length == 0 then
                { result: Ok lst, rest: bytes }
            else
                { result: elemResult, rest } = Decode.decodeWith bytes elemDecoder simpleEncoding
                when elemResult is
                    Ok elem -> decodeListHelper rest (length - 1) (List.append lst elem)
                    Err err -> { result: Err err, rest }

        { result: lengthResult, rest: restBytes } = Decode.decodeWith initialBytes decodeU64 simpleEncoding
        when lengthResult is
            Ok length -> decodeListHelper restBytes length (List.withCapacity length)
            Err err -> { result: Err err, rest: restBytes }

decodeRecord : state, (state, Str -> [Keep (Decoder state SimpleEncoding), Skip]), (state, SimpleEncoding -> Result val DecodeError) -> Decoder val SimpleEncoding
decodeRecord = \initialState, stepField, finalizer -> Decode.custom \initialBytes, @SimpleEncoding {} ->
        decodeRecordHelper = \bytes, length, state ->
            if length == 0 then
                { result: finalizer state simpleEncoding, rest: bytes }
            else
                { result: nameResult, rest: nameRestBytes } = Decode.decodeWith bytes decodeString simpleEncoding
                when nameResult is
                    Ok name ->
                        when stepField state name is
                            Keep decoder ->
                                { result: newStateResult, rest } = Decode.decodeWith nameRestBytes decoder simpleEncoding
                                when newStateResult is
                                    Ok newState -> decodeRecordHelper rest (length - 1) newState
                                    Err err -> { result: Err err, rest }

                            Skip -> { result: Err TooShort, rest: nameRestBytes }

                    Err err -> { result: Err err, rest: nameRestBytes }

        { result: lengthResult, rest: restBytes } = Decode.decodeWith initialBytes decodeU64 simpleEncoding
        when lengthResult is
            Ok fullLength -> decodeRecordHelper restBytes fullLength initialState
            Err err -> { result: Err err, rest: restBytes }

decodeTuple : state, (state, U64 -> [Next (Decoder state SimpleEncoding), TooLong]), (state -> Result val DecodeError) -> Decoder val SimpleEncoding
decodeTuple = \initialState, stepElem, finalizer -> Decode.custom \initialBytes, @SimpleEncoding {} ->
        dbg initialBytes

        decodeTupleHelper = \bytes, state, index ->
            when stepElem state index is
                Next decoder ->
                    { result: nextStateResult, rest: restBytes } = Decode.decodeWith bytes decoder simpleEncoding
                    when nextStateResult is
                        Ok nextState -> decodeTupleHelper restBytes nextState (index + 1)
                        Err err -> { result: Err err, rest: restBytes }

                TooLong ->
                    { result: Ok state, rest: bytes }

        { result, rest } = decodeTupleHelper initialBytes initialState 0
        when result is
            Ok state -> { result: finalizer state, rest }
            Err err -> { result: Err err, rest }
