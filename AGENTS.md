# AGENTS.md

## General Instructions & Guidelines for Agents

- **Secrets & API Keys**: Never commit secrets, credentials, or API keys to the repository. Ensure sensitive items are kept in ignored configuration files or environment variables.
- **Cross-Platform Support**: The app must support iOS, Android, and Flutter web.
- **Package Selection**: Avoid adding packages or dependencies that do not support web or mobile platforms.
- **Responsive Layouts**: Layouts must be responsive and function seamlessly on phone-sized screens as well as web browsers.
- **Pre-PR Verification**: Always run `flutter analyze` and `flutter test` before submitting code changes or opening a pull request. Fix all static analysis errors, warnings, and failing tests.
