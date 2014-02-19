# CASA Environment

An environment manager for the CASA reference implementation.

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
