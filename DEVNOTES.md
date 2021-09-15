# Developer Notes

## Release Process

To make a release:

1. decide upon a name that will start with the letter `v` and a semantic
   version, e.g. `v0.2.3`.
2. Add a section to the [CHANGELOG](./CHANGELOG.md), second-level of heading
   with the same name as the release name, e.g. `## v0.2.3`.
3. Create a git tag with the same name.
4. Push the tag, e.g. `git push --tags`.

The release workflow should automatically generate a GitHub release with this
information.
