# Roober
A Ruby rooter

[![Build Status](https://travis-ci.org/samrussell/roober.svg?branch=master)](https://travis-ci.org/samrussell/roober)
[![Code Climate](https://codeclimate.com/github/samrussell/roober/badges/gpa.svg)](https://codeclimate.com/github/samrussell/roober)
[![Test Coverage](https://codeclimate.com/github/samrussell/roober/badges/coverage.svg)](https://codeclimate.com/github/samrussell/roober/coverage)

## Why make another software router?

There are many software routers available, but Roober is different:

- Fully unit tested
- Doesn't talk to the kernel

### Unit testing

The main reason for writing a router from scratch was to build unit testing into it from the beginning. If roober is to be successful, it needs to be extensible, and testing is a vital part of this. Full test coverage also makes refactoring much less painful, and this encourages a lean and approachable codebase.

### No kernel bindings

Roober doesn't care where it runs; its job is to speak various routing protocols (currently only BGP), maintain a set of active routes and corresponding paths, and provide interfaces for other applications to access these routes. Do you want your routes in the kernel? Find an app for that! Roober will happily give you a route feed in whatever format you like :)

## Notes on licensing

This software is open source, and is made available here under the AGPLv3 license. If this license isn't suitable for your purposes, then please send me an email; I would be happy to arrange a more suitable license that meets your requirements.
