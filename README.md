# --filter='[main...HEAD]' reads the range as tip to tip

Fixed in https://github.com/vercel/turborepo/pull/13917, merged 2 Sep 2026.

Reproduction for https://github.com/vercel/turborepo/pull/13917.

With `filterUsingTasks` on, `--filter='[main...HEAD]'` diffs the two branch tips instead of merge base to head. So if `main` moved after you branched, packages you never touched get selected because they changed on `main`. The other direction is worse: a file that is byte identical on both tips because you cherry picked it does not show in a tip to tip diff, and that task is skipped.

Run it:

    ./repro.sh

It makes a branch that changes `my-app`, then changes `util` on `main` after the branch point, then runs turbo from the branch. Git agrees only `my-app` is in the range:

    git diff main...HEAD touches:
      apps/my-app/note.txt

but turbo selects both:

    turbo run build --filter='[main...HEAD]' selects:
      my-app#build
      util#build

To check the fix, pass a turbo built from #13917:

    ./repro.sh /path/to/turborepo/target/debug/turbo

It selects only `my-app#build`.

The cause is in `get_changed_files` in `crates/turborepo-lib/src/run/task_filter.rs`. It passes `merge_base` and `allow_unknown_objects` to `scm.changed_files` in the wrong order. Both are bools so nothing complains. The package level path in `change_detector.rs` has them the right way round.
