# CASA Environment

The [Community App Sharing Architecture (CASA)](http://imsglobal.github.io/casa) provides a mechanism for
discovering and sharing metadata about web resources such as websites, mobile
apps and LTI tools. It models real-world decision-making through extensible
attributes, filter and transform operations, flexible peering relationships,
etc.

This Ruby gem is part of the CASA reference implementation. It provides an
environment manager to setup and configure components of the reference
implementation.

## License

This software is **open-source** and licensed under the Apache 2 license.
The full text of the license may be found in the `LICENSE` file.

## Usage

### Development Environment

To configure development environment parameters, edit `config/dev.json`.

To set up the environment:

```
bundle exec thor env:dev:setup
```

To configure the environment, edit `config/dev.json` and then:

```
bundle exec thor env:dev:configure
```

To reset the configuration (should always before running configure again):

```
bundle exec thor env:dev:reset
```

To check current status of repositories in the development:

```
bundle exec thor env:dev:status
```

To update the repositories in the environment:

```
bundle exec thor env:dev:update
```

To destroy the environment (use with caution as this is permanent):

```
bundle exec thor env:dev:destroy
```
