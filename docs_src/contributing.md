# How to contribute

Thanks for reading this. We always welcome volunteers to help with refining this project.

Here are some important notes about how we manage this project:

This project was originally developed as a Confluent Customer Solutions and Innovation Divison (CSID) Accelerator.
More information about Accelerators can be found [here](https://www.confluent.io/confluent-accelerators/).

We use an internal JIRA project to track logical issues, including bugs and improvements. For contributors external to Confluent, the Github Issues queue should be used for requesting improvements or bug notifications.

Documentation for this project has one or more of the following:
- Github Pages set up for documentation
- README.md
- Wiki pages, internal to Confluent

We use Github pull requests to manage the review and merge of specific changes to the source code.

##Submitting changes

Find the existing Accelerator Github Issue ticket that the change pertains to.
Look for existing pull requests that are linked from the Github Issue ticket, to understand if someone is already working on it, so you can add to the existing discussion and work instead.

If the change is new, then it usually needs a new Github Issue ticket. However, trivial changes, where "what should change" is virtually the same as "how it should change" do not require a Github Issue ticket. Example: "Fix typos in Foo scaladoc"
If the change is a large change, consider inviting discussion in the issue first before proceeding to implement the change.

If required, create a new Github issue.

- Provide a descriptive Title. "Update web UI" or "Problem in scheduler" is not sufficient. "Kafka support fails to handle empty queue during shutdown" is good.
- Write a detailed Description. For bug reports, this should ideally include a short reproduction of the problem. For new features or integration, it may include a design document and reference URLs.
- Set optional field: Labels. (e.g., is this an enhancement request or a bug report?)

To avoid conflicts, assign the issue to yourself if you plan to work on it. Leave it unassigned otherwise.
Do not include a patch file; pull requests are used to propose the actual change.

##Pull Request
Fork the Github repository.

Clone your fork, create a new branch, push commits to the branch, and [review the Kafka Coding Guidelines](https://kafka.apache.org/coding-guide), if you haven't already).

Always write a clear log message for your commits. One-line messages are fine for small changes, but bigger changes should look like this:

    $ git commit -m "A brief summary of the commit
    > 
    > A paragraph describing what changed and its impact."

Consider whether documentation or tests need to be added or updated as part of the change, and add them as needed (doc changes should be submitted along with code change in the same PR).

Open a pull request against the master branch.

The PR title should usually be the Github issue’s title or a more specific title describing the PR itself. For trivial cases where an issue is not required, MINOR: or HOTFIX: should prefix the PR title.

If the pull request is still a work in progress, and so is not ready to be merged, but needs to be pushed to Github to facilitate review, then add [WIP] after the Title.

Consider identifying committers or other contributors who have worked on the code being changed. The easiest is to simply follow GitHub's automatic suggestions or request review from @csid-reviewers.

Please state that the contribution is your original work and that you license the work to the project under the project's open source license.

The project uses Apache Jenkins for continuous testing. A CI job will not be started automatically for pull requests from external contributors.

##Review Process
CSID reviewers, including committers, may comment on the changes and suggest modifications. Changes can be added by simply pushing more commits to the same branch.

Please add a comment and `@` the reviewer in the PR if you have addressed reviewers' comments. Even though GitHub sends notifications when new commits are pushed, it is helpful to know that the PR is ready for review once again.
Sometimes, other changes will be merged which conflict with your pull request's changes. The PR can't be merged until the conflict is resolved. This can be resolved with `git fetch origin` followed by `git merge origin/trunk` and resolving the conflicts by hand, then pushing the result to your branch.

Try to be responsive to the discussion rather than let days pass between replies.

## Updates and Feedback
Investigate and fix failures caused by the pull the request.
Fixes can simply be pushed to the same branch from which you opened your pull request.

Please address feedback via additional commits instead of amending existing commits. This makes it easier for the reviewers to know what has changed since the last review. All commits will be squashed into a single one by the committer via GitHub's squash button or by a script as part of the merge process.

##Closing Your Pull Request / Github Issue
If a change is accepted, it will be merged and the pull request will automatically be closed, along with the associated issue if any.
If your pull request is ultimately rejected, please close it.
