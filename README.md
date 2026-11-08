# Grenix Example

This is an example app using the minimal flake template from
[blaix/grenix](https://github.com/blaix/grenix).

The Gren application lives in `src/Main.gren`.

It's runnable and installable via npm or nix.
`package.json` is the source of truth for the app name, executable name, version, and description for both.

For example, with a `package.json` like this:

```json
{
  "name": "my-gren-app",
  "version": "0.1.0",
  "description": "A Gren command line application",
  "bin": {
    "my-app": "app"
  },
  ...
```

* The npm package name is `my-gren-app`
* The installed executable name is `my-app`
* The version is `0.1.0`
* The description is `"A Gren command line application"`

Update the values in `package.json` accordingly.

You'll also want to update the flake's `description` at the top of `flake.nix`.

## Develop

```sh
nix develop     # open a shell with all dev dependencies (defined in flake.nix)
gren run Main   # compile and run the app
npm run build   # compile ./app, which you can run with arguments
./app           # run the compiled app
nix flake check # verify it builds and runs via nix and npm
```

You can also run individual shell commands with all dependencies available, without opening a dev shell, with:

```sh
nix develop -c <command>
```

Note: Nix only sees files that git tracks, so `git add` new files before running `nix build` or `nix flake check`.

## Dependencies and compiler updates

Add dependencies with `gren package install author/name`, then commit `gren_packages/` along with `gren.json`.
Nix runs checks and builds in a sandbox, so if you forget to commit `gren_packages/`,
you'll get an error about a package it can't find.

You can update your flake dependencies with `nix flake update`.
If this updates the `gren` version, you'll need to update your `gren.json` to match
(or you'll get an `INCOMPATIBLE COMPILER` error).

## Releasing

### Bump the version

`package.json` is the source of truth for the version of both the npm package and the nix flake.

From a clean git tree, run:

```sh
npm version patch   # or minor, or major
```

That will update `package.json`, commit, and tag the repo
(you can also do these by hand).

### NPM

Run `npm login` first if you haven't before, then publish:

```sh
npm publish
```

(this will also run the build)

Then it can be installed or run like any other npm package:

```sh
npx <package-name>             # run without installing
npm install -g <package-name>  # or install it
<executable-name>              # and run the installed executable
```

### Nix Flake

You can also make the flake publicly available by pushing to a public repo:

```sh
git push --follow-tags
```

It will then be usable like any other flake via a `git+ssh://` or `git+https://` url.
Pushing to github will allow people to use the github shorthand:

```sh
nix run github:<you>/<repo>          # run without installing
nix profile add github:<you>/<repo>  # or install it
<executable-name>                    # and run the installed executable
```

Those will install/run the latest commit on the default branch.
To use a specific tag, branch, or commit, add it to the end:

```sh
nix run github:<you>/<repo>/v0.2.0
nix profile add github:<you>/<repo>/v0.2.0
```

You can also run it with nix locally via `nix run /path/to/repo`.
