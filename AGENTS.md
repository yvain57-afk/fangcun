# Project Collaboration Guide

## Scope

This repository contains an iOS app and its watchOS companion app.

## Working Rules

- Inspect the Xcode project and nearby code before making changes.
- Keep changes small, focused, and consistent with the existing architecture.
- Do not invent targets, schemes, bundle identifiers, entitlements, or file paths.
- Preserve user changes and avoid unrelated refactors.
- Never commit secrets, signing certificates, provisioning profiles, tokens, or private configuration.
- Do not add analytics, telemetry, or network calls unless explicitly requested.

## Swift and Apple Platform Code

- Prefer Swift concurrency and type-safe APIs when they match the deployment target.
- Keep iOS-only and watchOS-only behavior inside the appropriate targets or conditional compilation blocks.
- Put genuinely shared code in the project's established shared module or shared target membership.
- Treat HealthKit, notifications, background modes, App Groups, and WatchConnectivity changes as permission-sensitive changes.
- Maintain accessibility labels and Dynamic Type support for user-facing UI.

## Verification

- Run the fastest relevant build or test first.
- When schemes exist, verify each affected iOS or watchOS scheme.
- Add or update tests for behavior changes when a test target exists.
- Report commands run, failures, and any verification that could not be completed.

## Git

- Use `main` as the stable branch.
- Work in focused branches such as `feature/...`, `fix/...`, or `chore/...`.
- Do not rewrite shared history or use destructive Git commands without explicit approval.

