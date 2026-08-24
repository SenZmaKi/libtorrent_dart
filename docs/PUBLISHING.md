# Publishing to pub.dev

GitHub Releases are the source of the package's native assets. The release
workflow therefore publishes all nine GitHub assets before its `publish-pub`
job publishes the Dart package.

## One-time first publication

pub.dev requires the first version of a new package to be published by an
authenticated Google account. Publish the exact `v0.4.1` tag from a Git archive
so the initialized native submodule and local build outputs cannot enter the
package:

```sh
cd /path/to/libtorrent_dart

PUBLISH_DIR="$(mktemp -d /tmp/libtorrent-dart-pub.XXXXXX)"
git archive v0.4.1 | tar -x -C "$PUBLISH_DIR"
cd "$PUBLISH_DIR"

dart pub publish --dry-run
dart pub publish
```

The dry run must report `Package has 0 warnings`. The publish command opens a
browser for Google authentication and asks for confirmation before uploading.
Do not copy the local pub credential into GitHub Actions.

## Enable GitHub Actions publishing

After `0.4.1` appears on pub.dev:

1. Open `https://pub.dev/packages/libtorrent_dart/admin`.
2. Under **Automated publishing**, enable publishing from GitHub Actions.
3. Set the repository to `SenZmaKi/libtorrent_dart`.
4. Set the tag pattern to `v{{version}}`.
5. Do not require a GitHub environment unless the release workflow is also
   updated to name that environment.

No GitHub secret, pub token, private key, or service-account credential is
required. The official Dart reusable workflow exchanges GitHub's temporary
OIDC identity for permission to publish the matching version.

## Future versions

1. Update `version` in `pubspec.yaml` and add the release to `CHANGELOG.md`.
2. Commit and push `main`, then wait for the Tests workflow to pass.
3. Run `dart scripts/release.dart` from a clean `main` checkout.
4. Watch the Release workflow. It builds and publishes the GitHub assets, then
   publishes the same version to pub.dev.

The version in `pubspec.yaml`, the `v<version>` tag, and the GitHub release must
always match. Push `main` before its tag so the release target is present on the
default branch.
