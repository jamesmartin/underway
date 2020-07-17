# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased][unreleased]
- Nothing

## [2.0.0] - 2020-07-17
### Added
- `Underway::Api.configure` can now accept individual attributes instead of
  just a config file. When supplying a config file, the `app_root` is no longer
  required, just pass the absolute or relative path to the file

### Changed
- `Underway::Settings.config` is no longer supported. Use
  `Underway::Settings.configuration` instead
- `Underway::Settings.configuration.raw` is no longer supported. It is no
  longer possible to retrieve arbitrary values from the config

## [1.1.0] - 2019-05-21
### Added
- `Underway::Api.client_for` helper that returns a configured `Octokit` client
  for a given installation ID or access token

### Fixed
- Make Underway work for GHES
  [#7](https://github.com/jamesmartin/underway/pulls/7)

## [1.0.1] - 2018-05-09
### Fixed
- No longer require Sinatra to be installed
  [#4](https://github.com/jamesmartin/underway/issues/4)

## 1.0.0 - 2018-03-05
### Added
- First release

[unreleased]: https://github.com/jamesmartin/underway/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/jamesmartin/underway/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/jamesmartin/underway/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/jamesmartin/underway/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/jamesmartin/underway/compare/5c7f4d7d3bfc...v1.0.0
