interface PrioQueue
    exposes [empty, enqueue, dequeue]
    imports []

PrioQueue item a := { data : List item, priority : item -> Num a }

empty = \priority -> @PrioQueue { data: [], priority }

enqueue = \@PrioQueue { data: q, priority }, item ->
    dataWithEnqueuedItem = List.append q item
    data = heapifyUp { data: dataWithEnqueuedItem, priority }
    @PrioQueue { data, priority }

dequeue = \@PrioQueue { data: q, priority } ->
    queueAndItemRes =
        firstItem <- List.first q |> Result.try
        lastItem <- List.last q |> Result.map
        unprioritizedData = q |> List.set 0 lastItem |> List.dropLast 1
        data = heapifyDown { data: unprioritizedData, priority }
        newQueue = @PrioQueue { data, priority }
        (newQueue, firstItem)
    queueAndItemRes |> Result.mapErr \_ -> QueueWasEmpty

heapifyUp = \{ data: initialQueue, priority } ->
    heapifyUpAt = \q, item, idx ->
        if idx == 0 then
            List.set q idx item
        else
            parentIdx = ((idx - 1) // 2)
            parentItemRes = List.get q parentIdx
            when parentItemRes is
                Err OutOfBounds -> crash "Getting the parent should always be possible"
                Ok parentItem ->
                    if priority item < priority parentItem then
                        newQueue = List.set q idx parentItem
                        heapifyUpAt newQueue item parentIdx
                    else
                        List.set q idx item
    when initialQueue is
        [] -> crash "Heapifying up should happen after insertion, but was done on an empty queue"
        [.., tail] -> heapifyUpAt initialQueue tail (List.len initialQueue - 1)

heapifyDown = \{ data: initialQueue, priority } ->
    heapifyDownAt = \q, item, idx ->
        rightIdx = (idx + 1) * 2
        leftIdx = rightIdx - 1
        rightChildRes = List.get q rightIdx
        leftChildRes = List.get q leftIdx
        when (leftChildRes, rightChildRes) is
            (Err _, Ok _) -> crash "Binary heaps are full binary trees. Can't have a righ branch if there isn't a left one"
            (Ok left, Err _) if priority left < priority item ->
                newQueue = List.set q idx left
                heapifyDownAt newQueue item leftIdx

            (Ok left, Ok right) if priority left < priority item || priority right < priority item ->
                if priority left <= priority right then
                    newQueue = List.set q idx left
                    heapifyDownAt newQueue item leftIdx
                else
                    newQueue = List.set q idx right
                    heapifyDownAt newQueue item rightIdx

            _ -> List.set q idx item

    when initialQueue is
        [] -> initialQueue
        [head, ..] -> heapifyDownAt initialQueue head 0

expect
    identity = \a -> a
    data = [9, 1, 2, 3]
    expected = [1, 3, 2, 9]
    actual = heapifyDown { data, priority: identity }
    expected == actual

expect
    identity = \a -> a
    data = [2, 3, 4, 1]
    expected = [1, 2, 4, 3]
    actual = heapifyUp { data, priority: identity }
    expected == actual
