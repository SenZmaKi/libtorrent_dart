import 'dart:io';
import 'package:yaml/yaml.dart';

void main() async {
  // 1. Read and parse pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('Error: pubspec.yaml not found.');
    exit(1);
  }

  final doc = loadYaml(await pubspecFile.readAsString());
  final version = doc['version'] as String?;

  if (version == null) {
    print('Error: No version found in pubspec.yaml.');
    exit(1);
  }

  final tagName = 'v$version';

  // 2. Safety Check: Ensure no uncommitted changes
  final status = await Process.run('git', ['status', '--porcelain']);
  if (status.stdout.toString().isNotEmpty) {
    print('Error: You have uncommitted changes.');
    exit(1);
  }

  print('Initiating release for $tagName...');

  // 3. Create the tag locally
  final tagResult = await Process.run('git', ['tag', tagName]);
  if (tagResult.exitCode != 0) {
    print('Error creating tag: ${tagResult.stderr}');
    exit(1);
  }

  // 4. Push the current branch first
  // This prevents the "Commit does not belong to any branch" error
  print('Pushing branch to origin...');
  final pushBranch = await Process.run('git', ['push', 'origin', 'HEAD']);
  if (pushBranch.exitCode != 0) {
    print('Error pushing branch: ${pushBranch.stderr}');
    exit(1);
  }

  // 5. Push the tag
  // This will trigger the GitHub Action 'on: push: tags'
  print('Pushing tag $tagName to origin...');
  final pushTag = await Process.run('git', ['push', 'origin', tagName]);
  if (pushTag.exitCode != 0) {
    print('Error pushing tag: ${pushTag.stderr}');
    exit(1);
  }

  print('Deployment sequence initiated.');
}
