---
title: Introduction
layout: gem-single
name: dry-system
type: gem
sections:
  - container
  - booting
  - auto-import
  - component-providers
  - plugins
  - settings
  - test-mode
---

Object dependency management system based on [dry-container](/gems/dry-container) and [dry-auto_inject](/gems/dry-auto_inject) allowing you to configure reusable components in any environment, set up their load-paths, require needed files and instantiate objects automatically with the ability to have them injected as dependencies.

This library relies on very basic mechanisms provided by Ruby, specifically `require` and managing `$LOAD_PATH`. It doesn't use magic like automatic const resolution, it's pretty much the opposite and forces you to be explicit about dependencies in your applications.

It does a couple of things for you:

* Provides an abstract dependency container implementation
* Handles `$LOAD_PATH` configuration
* Loads needed files using `require`
* Resolves object dependencies automatically
* Supports auto-registration of dependencies via file/dir naming conventions
* Supports multi-system setups (ie your application is split into multiple sub-systems)
* Supports configuring component providers, which can be used to share common components between many systems
* Supports test-mode with convenient stubbing API

To put it all together, this allows you to configure your system in a way where you have full control over dependencies and it's very easy to draw the boundaries between individual components.

This comes with a bunch of nice benefits:

* Your system relies on abstractions rather than concrete classes and modules
* It helps in decoupling your code from 3rd party code
* It makes it possible to load components in complete isolation. In example you can run a single test for a single component and only required files will be loaded, or you can run a rake task and it will only load the things it needs.
* It opens up doors to better instrumentation and debugging tools

You can use dry-system in a new application or add it to an existing application. It should Just Work™ but if it doesn't please [report an issue](https://github.com/dry-rb/dry-system/issues).

### Rails support

If you want to use dry-system with Rails, it's recommended to use [dry-rails](/gems/dry-rails) which sets up application container for you and provides additional features on top of it.

### Credits

* dry-system has been extracted from an experimental project called Rodakase created by [solnic](https://github.com/solnic). Later on Rodakase was renamed to [dry-web](https://github.com/dry-rb/dry-web).
* System/Component and lifecycle triggers are inspired by Clojure's [component](https://github.com/stuartsierra/component) library by [Stuart Sierra](https://github.com/stuartsierra)

