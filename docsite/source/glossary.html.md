---
title: Glossary
layout: gem-single
name: dry-system
---

**Container:** The container is central to dry-system. When you use dry-system, your very first step is to create your own `Dry::System::Container` subclass, which will be the class you use to manage and access all of your application’s **components**.

**Component:** A component is an item registered in the **container**, representing an object within your application. Each component has a **key**, which you can pass to `#[]` to **resolve** its **instance** from the container.

**Component key:** A component’s **key** is a string that uniquely identifies that component within the **container**. You can **resolve** a component from the **container** by passing its key to `#[]`.

**Registration** (or **manual registration**): You can manually register a **component** in the **container** via its `#register` method, passing the component's **key**, along with either a block that returns a new **instance** of the component (which will be called whenever the component is **resolved**), or a single object (to be returned as the **instance** value whenever the component is resolved).

**Component resolution:** You can **resolve** a component from the **container** by providing its **key** to the container’s `#[]` method. When you resolve a component, it will either return a new object **instance** each time (when the component is **auto-registered**, or when **manually registered** with a block), or return a single object every time (when the component is **manually registered** with an object instead of a block, or when the component is determined as a **singleton** or **memoized** during **auto-registration**).

**Component dir:** You can configure a container with one or more component dirs, which are the directories containing the **source files** for your components. The container **auto-registers** its components from the source files in these component dirs.

**Source file:** A source file is a `.rb` Ruby source file inside a **component dir**, defining a single class with a name corresponding to the file. The container loads this file during **auto-registration** to register a matching **component**.

**Auto-registration:** Auto-registration one of the main reasons to use dry-system: it makes it easy to work with applications consisting of a large number of components. The container **auto-registers** components both when you **finalize** it, as well as when you **resolve** a component while the container is **lazy loading.**  When auto-registering, the container automatically registers a **component** for the class defined in each **source file** in each of its **component dirs**. The container matches the component to its source file based on the source file’s name and any **namespaces** you have configured in the component dirs.

**Manifest registration:** You can create one or more registration manifest files, containing code that **manually registers** one or more components in the container. These files are searched during **auto-registration** to allow those components to be registered and **resolved** during both **finalization** and **lazy loading**.

**Finalization:** When you **finalize** a container, it begins a one-off process that **auto-registers** components for all the **source files** in its **components dirs**. One a container is finalized, it is frozen and no more components can be registered. Typically, you finalize a container as part of booting a long-running application process.

**Lazy loading:** A non-finalized container will lazily load individual components when you resolve them (as well as all the components for their dependencies, for components using **auto-injection**). This uses the same **auto-registration** process as when you **finalize** the container, ensuring your components are consistently available in both modes. Typically, you leave the container to lazy load when you want to optimise for fastest possible container load time, such as when running tests or your application in development mode.

**Auto-injection:** The auto-injector is a module from the **container** that you can mix into your own classes to declare their dependencies using **container keys**. The auto-injector will automatically define an initializer that **resolves** those dependencies from the container. This means you can initialize your object with `.new` alone, with its default dependencies resolved and assigned to instance variables automatically, while still allowing you to provide manual replacements for zero or more of those dependencies as explicit arguments to `.new`. Auto-injection combined with **auto-registration** means you can resolve a single component from your container and have all of its dependencies auto-registered and resolved in turn. When the container is **lazy loading**, this also allows an individual component to be resolved in the shortest possible time.

Component dir namespace

Key namespace

Const namespace

Loading (aka the loader)

Autoloading

Memoized components

Component provider ("Provider" for short)

Component provider lifecycle

Provider pack

Stubs

Importing containers

Plugins
