---
---

## Intro
- We are tasked to model a hospital's triaging system.
- We are interested in how long the patients have to wait before they get checked and whether they get infected by other waiting patients or not.
- What is DES? Generators, Entities, events, resources, activities
- We are not creating a general des library, but rather a direct implementation for our task,
- However, the data structures implemented are easy to separate out, so they are their own modules, behind opaque types.

## Part 1
- Writing the main event loop (using a tail recursive function) it needs PrioQueue data structure
- Writing a simple priority queue. Opaque, so that we can swap out the implementation in the final part. It is a list. Enqueuing is appending, dequeuing is a linear search.
- Generation events are scheduled into a priority queue. When the event is processed, the generated patient is just put into the patientsProcessed list as if we are done with them.
- Randomness is essential to simulations. Patients are generated, either healthy or sick, 50-50%, using a pseudo-random library. They have an evenly distributed random inter-arrival time between top-declared constant.

## Part 2
- Patients arrive in a queue and wait for a doctor to be available. Done with scheduling TriageDone events.
- Creating an opaque Queue data structure. It is implemented as a circular buffer with fixed capacity (a waiting room has a fixed size as well). Explain the data structure with illustrations. 

## Part 3
- Patients can infect each other while waiting in the queue. At arrival, an Interaction event is scheduled for that patient. After they interact with someone, another Interaction is scheduled.
- The patient chooses a random partner to interact with when the Interaction event is processed.
- If one of the patient is sick and the other is healthy, the healty will become infected.
- Constants were chosen carefully but: What happens if the patient has already been triaged and left the system before the Interaction event was processed? Change the constants so that it happens. Event cancellation is frequent in des, but we will not do that We manually handle in the main codebase when an Interaction event refers to a patient that has left the system.

## Part 4
- Createing a report from the results. Just printing out a string with some calculated data like average wait time and the % of healthy arrivals that got infected. Interpreting the results is a non-goal of this chapter.
-  Swap out the Priority Queue implementation to be a list-backed binary heap. Explain the data structure with illustrations. 

## Questions and Challanges
1. In the industry, you are usually not writing your own event loop. One small step towards creating a des library would be an event loop that executes event handlers for arbitrary events. You would specify the event type and a handler; the library would do the rest! The How would you implement that? What is the benefit of the current implementation compared to that?
2. Implement event cancellation, so that we can remove a patient's Interaction event from the event queue when a patient leaves the system.
3. What if the triage is so important that all patients are willing to wait, no matter the length of the queue? In this case there would be no Err QueueWasFull on enqueuing, but the queue would grow dynamically (maybe patients wait in the hall... or on the street?) Modify the Queue to grow that way. The current implementation is pretty efficient. How could you keep close to it?

