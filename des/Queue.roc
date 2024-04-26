interface Queue
    exposes [empty, find, getAt, setAt, len, enqueue, dequeue]
    imports []

Queue a := {
    data : List a,
    front : U64,
    back : U64,
    len : U64,
    capacity : U64,
}
    implements [Eq]

empty = \capacity -> @Queue {
        data: List.withCapacity capacity,
        front: 0,
        back: 0,
        len: 0,
        capacity,
    }

find = \@Queue q, condition ->
    List.walkWithIndexUntil q.data (Err NotFound) \state, elem, idx ->
        if condition elem then
            Break (Ok (idx, elem))
        else
            Continue state

getAt = \@Queue q, index ->
    List.get q.data index

setAt = \@Queue q, index, value ->
    data = List.set q.data index value
    @Queue { q & data }

len = \@Queue q -> q.len

enqueue = \@Queue q, element ->
    if q.len == q.capacity then
        Err QueueWasFull
    else
        newData =
            if List.len q.data < q.capacity then
                List.append q.data element
            else
                List.set q.data q.back element
        Ok (@Queue { q & data: newData, len: q.len + 1, back: (q.back + 1) % q.capacity })

dequeue = \@Queue q ->
    if q.len == 0 then
        Err QueueWasEmpty
    else
        newQueue = { q & front: (q.front + 1) % q.capacity, len: q.len - 1 }
        element =
            when List.get q.data q.front is
                Err OutOfBounds -> crash "front of queue was pointing outside of the queue"
                Ok elem -> elem
        Ok (@Queue newQueue, element)

expect
    queue = empty 1 |> enqueue A |> Result.try \q -> q |> enqueue B
    queue == Err QueueWasFull

expect
    queue = empty 1 |> dequeue
    queue == Err QueueWasEmpty

expect
    capacity = 1
    queue = empty capacity |> enqueue A
    queue == Ok (@Queue { data: [A], front: 0, back: 0, len: 1, capacity: capacity })

expect
    capacity = 1
    dequeued = empty capacity |> enqueue A |> Result.try \q -> q |> dequeue
    dequeued == Ok ((@Queue { data: [A], front: 0, back: 0, len: 0, capacity: capacity }, A))

expect
    capacity = 1
    queue =
        q <- empty capacity |> enqueue A |> Result.try
        (deq, _) <- q |> dequeue |> Result.try
        deq |> enqueue B
    queue == Ok (@Queue { data: [B], front: 0, back: 0, len: 1, capacity: capacity })

