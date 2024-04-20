---
---

## Outline

- What is a CI system?
  [OPEN QUESTION] Is this section useful?
  - CI: scripts that run automatically when code is changed
    - To gate what gets merged into the project (automated tests)
    - To automate common tasks (releases)
    - Because the scripts run too slow on a regular computer
  - CI system: software that runs these scripts.
    - Examples: Github Actions, Jenkins, ...
- We're going to design a CI system. Goals:
  - Allow CI scripts to be written in the Roc language
  - CI steps can run in parallel to make CI complete faster
  - CI can produce clear reports on (failed) runs
  - CI script created this way can be ran by, for instance, Github Actions
    - Because Github Actions is free for open source projects, so commonly used
- We're going to design the CI around an example project:
  [OPEN QUESTION] seem reasonable to use a roc project as the CI example in a Roc book?
  - A Roc library, using git for version control
  - CI runs tests and performs a release of the library if they pass:
    - Run tests in library code itself
    - Checks for errors in example apps bundled with library
    - Create a release bundle on Github
    - Build documentation for library and push to static site
      [OPEN QUESTION] github pages / Netlify / ... ?
  - [OPEN QUESTION] add a github-actions yml stub for automatically running this script on Github?

- First iteration: a single script that performs the above tasks in order
  - Script written in Roc using the basic-cli platform
  - Helper functions for different CI steps, `main` calls the helpers in order.
- Reflect:
  - Nice: script can be ran locally and by CI server with equal ease (many CI systems don't have this property)
  - Not nice: output is a single logfile. Error presentation does not have a clear format like:
    Step X failed, for reason Y
  - Single script, no opportunities to run parts of it in parallel for faster CI
  - Fails on first error, does not accumulate as much errors from parallel branches as possible

- Second iteration: Allow CI system to run steps in parallel on different machines
  - This requires the CI system to know the structure of the CI script before running it, specifically:
    - What steps does the script consist off?
    - What are the dependencies between the steps
      - Important for figuring out running order, and what can be parallelized
  - Additionally, if we're going to run steps in different processes on different machines, when one step wishes to pass some data to a subsequent step, we need to serialize/deserialize that data.
  - Propose design for a data type that contains the information the CI system needs to be able to orchestrate a parallelized build:
    ```roc
    Job : List Step

    Step : {
        name : Str,      # assuming each step to have a unique name
        dependencies : List Str,
        run : List U8 -> Task (List U8) Str,
    }
    ```
  - Now for designing an API to construct values of the above type
    - Motivation: having to manually construct these values would be error prone (circular dependencies, missing dependencies), and unergonomic (serializing/deserializing each step)
    - Design consideration: the API in our previous iteration was in many ways ideal: our 'CI system' was a plain Roc script, so no special knowledge was required to write CI. Let's keep as close to this design as we can.
    - In the spirit of the above, let's not change anything about the functions we had implementing individual steps.
    - We have to change our `main` though. Present proposed design
      ```roc
      job : Ci.Job
      job =
          repoDetails <- Ci.step0 "setup git" Ci.setupGit

          testsPass <- Ci.step1 "run tests" repoDetails
          docs <- Ci.step1 "build documentation" repoDetails
          release <- Ci.step1 "build release" repoDetails

          {} <- Ci.step2 "publish release" testsPass release
          {} <- Ci.step2 "publish documentation" testsPass docs

          Ci.done
      ```
      This looks reasonably similar to the main we had before. Instead of directly calling the step functions, we wrap the function calls into one of the `Ci.stepX` functions.
    - Show how we can implement the `Ci` module to make the API above produce a `Job` value.
    - Show how we can implement code that runs a `Job` value, still using the basic-cli platform.
- Reflect:
    - Our CI now parallelizes steps when possible
    - Our system executes as large a part of the step graph as it can instead of failing on the first error.
    - We will be able to improve CI output, grouping it by step
    - Within a step output could still be improved. Would be nice to see each individual command run, and then the stdout/stderr of that individual command below.


- Third iteration: custom task type to control effects performed in task steps
  [OPEN QUESTION] is this too much? Can be cut if so.
    - Currently CI scripts can make use of any Task-returning function supported by the basic-cli platform. If we define our own Task type then we can limit effects ran to functions that we provide, and then ensure those functions format output in particular ways.
    - Show implementation of a custom Task type that wraps the platform's Task type, implement basics of Task API.
    - Implement library functions for printing a line to stdout and one for running a command.
    - Update example to use the new helpers
- Reflect:
    - We can now fully customize presentation of tasks run by the script.
    - Downside is that users of the CI system will no longer be able to rely on their familiarity with the Tasks provided by the basic-cli platform. That seems okay though, having environments supporting different types of effectfull function is a core tenet of the Roc language.

- Ideas for further iterations:
  - Turn CI system from a library into a platform
    - Get benefits of controlling effects without needing a custom Task type
  - Produce pipeline specifications for other CI systems (like Github Actions) from `Job` values.
    - Makes it possible to use Roc-ci specifications in many commonly used (sometimes free) CI systems.
