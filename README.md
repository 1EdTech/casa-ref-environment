# CASA Bootstrap

## Usage

### Development Environment

```
mkdir casa-bootstrap
curl -L -0 https://api.github.com/repos/AppSharing/casa-bootstrap/tarball | tar -zx -C casa-bootstrap --strip-components 1
cd casa-bootstrap
bundle
thor dev:setup
```