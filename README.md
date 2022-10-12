# Rang Blog

This is the codebase for my blog which is found at srang.github.io/samuelrang.com/

There are two key branches for this repo, the `main` branch which is the core of the code base, and from `main` the `gh-pages` branch is built

## Running Locally

All actions for developing the blog leverage the `sm` shell tool. In order to build and deploy locally, run `./sm b s` which will build the codebase and then serve locally.

Once the application begins to serve, it will automatically refresh and load new or updated posts. To shutdown local server, run `./sm k`

## Publishing

After changes are complete and ready for publishing, run `./sm p` to package the site and publish to the `gh-pages` branch
