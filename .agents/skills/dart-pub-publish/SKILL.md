---
name: dart-pub-publish
description: Publish Dart/Flutter packages to pub.dev — version check, SemVer bump, changelog, dry-run.
---

For each publishable package, run from its directory (the folder with `pubspec.yaml`).

## 1. Should this package be published?

Compare local `version` to pub.dev. On success, also print the commit that set the **published** version — the baseline for changes since last release.

```bash
name=$(grep -E '^name:' pubspec.yaml | sed 's/name: *//')
local=$(grep -E '^version:' pubspec.yaml | sed 's/version: *//')
code=$(curl -s -o /tmp/pub_pkg.json -w "%{http_code}" "https://pub.dev/api/packages/$name")
if [ "$code" != "200" ]; then
  echo "unpublished local=$local"
else
  remote=$(jq -r .latest.version /tmp/pub_pkg.json)
  commit=$(git log -1 --format=%H -G "^version:[[:space:]]*${remote}" -- pubspec.yaml)
  if [ "$local" = "$remote" ]; then
    echo "match version=$local commit=$commit"
  else
    echo "mismatch local=$local remote=$remote commit=$commit"
  fi
fi
```

```powershell
$name = (Get-Content pubspec.yaml | Select-String '^name:\s*(.+)').Matches.Groups[1].Value.Trim()
$local = (Get-Content pubspec.yaml | Select-String '^version:\s*(.+)').Matches.Groups[1].Value.Trim()
try {
  $remote = (Invoke-RestMethod "https://pub.dev/api/packages/$name").latest.version
  $commit = git log -1 --format=%H -G "^version:\s*$remote" -- pubspec.yaml
  if ($local -eq $remote) { "match version=$local commit=$commit" }
  else { "mismatch local=$local remote=$remote commit=$commit" }
} catch {
  # Missing package: WebException / NoSuchKey — not a JSON body
  "unpublished local=$local"
}
```

| Result | What to do |
|--------|------------|
| `unpublished` | First publish of `local`. Continue. |
| `mismatch`, local **ahead** of remote | Publish `local` as-is. Continue. |
| `mismatch`, local **behind** remote | Stop; investigate. |
| `match`, no package changes after `commit` | Stop; nothing to publish. |
| `match`, package changes after `commit` | Bump `version` (SemVer). Continue. |

## 2. Update CHANGELOG.md

Create if missing. Cover changes since the last release (`commit=` when present).

## 3. Dry-run

Keep output from `Validating package` onward:

```bash
dart pub publish --dry-run 2>&1 | sed -n '/Validating package/,$p'
```

```powershell
dart pub publish --dry-run 2>&1 | ForEach-Object -Begin { $show = $false } -Process {
  if (-not $show -and "$_" -match 'Validating package') { $show = $true }
  if ($show) { $_ }
}
```

## 4. Report

Summarize version/changelog changes and dry-run issues. Don't run `dart pub publish` unless the user asks.
