# Human intent

This repository writes down what people want before building it. Every sentence in this directory is something somebody wants, and each one has an id that never moves and is never reused.

Before you build a feature:

1. Read the files here, so you know what has already been said.
2. Draft the criteria for what you are about to build, as plain sentences about what somebody wants rather than what the code will do.
3. Ask the person to confirm them. Nothing lands that they did not agree to.
4. Capture what they agreed to, then build it.

That happens before every feature, not only the first one.

After a merge that touched this directory, run `hi check`. Two branches can each choose the same id, and git will merge both without saying anything.

Write the prose in these files as one line per paragraph, with a blank line between paragraphs. A newline inside a paragraph is a visible break wherever the file is rendered, and it was only ever where your editor wrapped.

Run `hi --help` for the commands.
