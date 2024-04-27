app "des"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br",
        random: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.1.0/OoD8jmqBLc0gyuaadckDMx1jedEa03EdGSR_V4KhH7g.tar.br",
    }
    imports [pf.Stdout, random.Random, PrioQueue, Queue]
    provides [main] to pf

timeAfterArrivalsStop = 100
triageTime = 6
interactionTime = 5
interArrivalTimeMin = 2
interArrivalTimeMax = 3
expect interArrivalTimeMin <= interArrivalTimeMax 

defaultWorld =
    seed = 42
    availableDoctors = 2
    waitingRoomCapacity = 50
    {
        time: 0,
        random: Random.seed seed,
        availableDoctors,
        patientsWaiting: Queue.empty waitingRoomCapacity,
        events: PrioQueue.empty .time |> PrioQueue.enqueue { time: 0, type: Generation 0 },
        patientsProcessed: [],
    }

main =
    simulatedWorld = processEvents defaultWorld
    report = createReport simulatedWorld
    Stdout.line report

createReport = \{ patientsProcessed: patients, time } ->
    healthyCount = List.countIf patients \p -> p.state == Healthy
    infectedCount = List.countIf patients \p -> p.state == Infected
    healthyAtArrivalCount = healthyCount + infectedCount
    infectedRatio = Num.toFrac infectedCount / Num.toFrac healthyAtArrivalCount
    infectedRatioPercentage = infectedRatio |> Num.mul 100 |> roundToPrecision 2

    patientCount = List.len patients
    avgWaitTime =
        waitTimes = List.map patients \p -> p.triageDoneAt - p.arrivedAt
        (List.sum waitTimes |> Num.toFrac) / (Num.toFrac patientCount) |> roundToPrecision 2

    """
    Processed $(Num.toStr patientCount) patients in $(Num.toStr time) minutes.
    $(Num.toStr healthyAtArrivalCount) arrived healthy, $(Num.toStr infectedCount) were infected while waiting.
    That is $(Num.toStr infectedRatioPercentage)% of the healthy arrivals.
    Patiens had an average wait time of $(Num.toStr avgWaitTime) minutes.
    """

# workaround for the lack of Frac to Str formatting with precision
# todo: delete this comment before release if there isn't a better a solution
roundToPrecision = \num, decimalCount ->
    tenToThePrecisionth = Num.powInt 10 decimalCount |> Num.toFrac
    num * tenToThePrecisionth |> Num.round |> Num.toFrac |> Num.div tenToThePrecisionth

processEvents = \world ->
    nextEvent = world.events |> PrioQueue.dequeue
    when nextEvent is
        Err QueueWasEmpty -> world
        Ok (remainingEvents, e) ->
            newWorld = handleEvent { world & time: e.time, events: remainingEvents } e
            processEvents newWorld

handleEvent = \world, { type: eventType } ->
    when eventType is
        Generation patientId -> handleGeneration world patientId
        Interaction patientId -> handleInteraction world patientId
        TriageDone patientId -> handleTriageDone world patientId

handleInteraction = \world, patientId ->
    choice = chooseInterationPartner world patientId
    when choice is
        Err TooFewPatients -> world
        Err (IteractorNotFound newRandom) -> { world & random: newRandom }
        Ok { patientChoices, newRandom } ->
            patientsAfterContact = interactPatients world.patientsWaiting patientChoices
            { world &
                random: newRandom,
                patientsWaiting: patientsAfterContact,
            }

chooseInterationPartner = \{ patientsWaiting, random }, interactorId ->
    patientsWaitingCount = Queue.len patientsWaiting
    if patientsWaitingCount < 2 then
        Err TooFewPatients
    else
        lastPatientIdx = Num.toU32 (patientsWaitingCount - 1)
        randomGen = Random.u32 0 lastPatientIdx
        { state: newRandom, value: targetIdxU32 } = randomGen random
        partnerIdx = Num.toU64 (targetIdxU32)
        partner =
            when Queue.getAt patientsWaiting partnerIdx is
                Ok patient -> patient
                Err OutOfBounds -> crash "random index generated incorrectly"

        src = Queue.find patientsWaiting (\patient -> patient.id == interactorId)
        when src is
            Err NotFound -> Err (IteractorNotFound newRandom)
            Ok (interactorIdx, interactor) -> Ok { newRandom, patientChoices: { interactorIdx, interactor, partner, partnerIdx } }

interactPatients = \patients, { interactorIdx, interactor, partnerIdx, partner } ->
    when (interactor.state, partner.state) is
        (Healthy, Sick) | (Healthy, Infected) -> Queue.setAt patients interactorIdx { interactor & state: Infected }
        (Sick, Healthy) | (Infected, Healthy) -> Queue.setAt patients partnerIdx { partner & state: Infected }
        _ -> patients

handleGeneration = \world, id ->
    { time, events, random } = world
    if time > timeAfterArrivalsStop then
        world
    else
        { state: randomAfterArrivalTime, value: interArrivalTime } =
            randomGenInterArrivalTime = Random.u32 interArrivalTimeMin interArrivalTimeMax
            randomGenInterArrivalTime random

        generationEvent = { time: time + interArrivalTime, type: Generation (id + 1) }
        eventsWithGeneration = events |> PrioQueue.enqueue generationEvent
        worldWithGeneration = { world & events: eventsWithGeneration }

        randomGen = Random.u32 0 1
        { state: newRandom, value: healthyOrSick } = randomGen randomAfterArrivalTime
        state =
            if healthyOrSick == 0 then
                Sick
            else
                Healthy

        patient = { id, arrivedAt: time, state }
        worldWithNewRandom = { worldWithGeneration & random: newRandom }
        patientArrived worldWithNewRandom patient

patientArrived = \world, patient ->
    { time, patientsWaiting, events } = world
    when tryTriagingPatient world patient is
        Ok worldWithTriagedPatient ->
            worldWithTriagedPatient

        Err NoAvailableDoctors ->
            newPatients = Queue.enqueue patientsWaiting patient |> Result.withDefault patientsWaiting
            interactionEvent = { time: time + interactionTime, type: Interaction patient.id }
            eventsWithInteraction = events |> PrioQueue.enqueue interactionEvent
            { world & events: eventsWithInteraction, patientsWaiting: newPatients }

tryTriagingPatient = \world, patient ->
    if world.availableDoctors > 0 then
        Ok (triagePatient world patient)
    else
        Err NoAvailableDoctors

triagePatient = \world, patient ->
    { time, events, availableDoctors } = world
    triageDoneEvent = { time: time + triageTime, type: TriageDone patient }
    newEvents = events |> PrioQueue.enqueue triageDoneEvent
    { world & events: newEvents, availableDoctors: availableDoctors - 1 }

handleTriageDone = \world, patient ->
    { patientsWaiting, patientsProcessed, availableDoctors, time } = world
    patientDetails = { state: patient.state, arrivedAt: patient.arrivedAt, triageDoneAt: time }
    newPatientsProcessed = List.append patientsProcessed patientDetails
    worldWithTriageDone = { world & availableDoctors: availableDoctors + 1, patientsProcessed: newPatientsProcessed }
    when Queue.dequeue patientsWaiting is
        Ok (remainingPatients, patientNextInLine) ->
            triagePatient { worldWithTriageDone & patientsWaiting: remainingPatients } patientNextInLine

        Err QueueWasEmpty -> worldWithTriageDone
