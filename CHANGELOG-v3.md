# v3 changes

- Fixed GitHub Actions run 29157863459 / job 86557879048 failure.
- Enabled Godot iOS `application/export_project_only` mode.
- Removed fake Apple Team ID requirement from unsigned build configuration.
- Added a valid Godot-only placeholder Team ID for project generation.
- Explicitly disabled the unused iOS camera module.
- Moved ATS modification to post-export Info.plist patching.
- Added PBX project and Info.plist validation before Xcode compilation.
- Added actionable generated-project diagnostics to build artifacts.
