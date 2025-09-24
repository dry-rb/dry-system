---
title: Glossary
layout: gem-single
name: dry-system
---

## The basics

**Container:** The container is central to dry-system. When you use dry-system, your very first step is to create your own `Dry::System::Container` subclass, which will be the class you use to manage and access all of your application’s **components**.

**Component key:** A component’s **key** is a string that uniquely identifies that component within the **container**. You can **resolve** a component from the **container** by passing its key to the container’s `.[]` method.

**Component:** A component is an item registered in the **container**, representing an object within your application. Each component has a **key**, which you can pass to `.[]` to **resolve** its **instance** from the container.

**Component resolution:** You can **resolve** a component from the container by providing its **key** to the container’s `.[]` method. Whenever you resolve a component, it will either build and return a new component **instance** (when the component is **auto-registered**, or when **manually registered** with a block), or return a single instance (when the component is **manually registered** with an object instead of a block, or when the component is **auto-registered** and is configured to be **memoized** or is determined to be a **singleton**).

**Component instance**: A component instance is a simple object from your application, with all its dependencies already provided (courtesy of **auto-injection**), ready for you to use. You receive a component instance when you **resolve** it from the container. If you had **manually registered** the component, then its instance will be the object you provided when registering it. Otherwise, it will typically be an instance of a class that has been **auto-registered** from one of your **component dirs**.

**Auto-injection:** The auto-injector is a module from the **container** that you can mix into your own classes to declare their dependencies using **container keys**. The auto-injector will automatically define an initializer that **resolves** those dependencies from the container. This means you can initialize your object with `.new` alone, with its default dependencies resolved and assigned to instance variables automatically, while still allowing you to provide manual replacements for zero or more of those dependencies as explicit arguments to `.new`. Auto-injection combined with **auto-registration** means you can resolve a single component from your container and have all of its dependencies auto-registered and resolved in turn. When the container is **lazy loading**, this also allows an individual component to be resolved in the shortest possible time.

## Component registration

**Component dir:** You can configure a container with one or more component dirs, which are the directories containing the **source files** for your components. The container **auto-registers** its components from the source files in these component dirs.

**Source file:** A source file is a `.rb` Ruby source file inside a **component dir**, defining a single class with a name corresponding to the file. The container loads this file during **auto-registration** to register a matching **component**. (TODO: A source file may have **magic comments** to control its registration behavior)

**Auto-registration:** Auto-registration is one of the main reasons to use dry-system: it makes it easy to work with applications consisting of a large number of components. The container **auto-registers** components both when you **finalize** it, as well as when you **resolve** a component while the container is **lazy loading.**  When auto-registering, the container automatically registers a **component** for the class defined in each **source file** in each of its **component dirs**. The container matches the component to its source file based on the source file’s name and any **namespaces** you have configured in the component dirs.

**Provider:** A provider manages the lifecycle around configuring and registering one or more components (or setting global state if necessary) required for distinct parts of your application to work. When you register a provider (by creating a **provider file** in your **provider path**), you provide code to run for one or more of its **lifecycle hooks**, `prepare`, `start`, and `stop`. You typically create a provider when you need to register components with particular configuration (such as a client for a third party service, requiring API keys and other connection details) or when components are particularly heavyweight (such as a database persistence system). Every provider has a unique **name** that also corresponds to a **container key** **namespace**. Whenever any **component** in that namespace is **resolved** from the container, then the provider will be **started** (with its `prepare` and `start` hooks run in sequence). Providers can also be individually controlled via the container's `.prepare`, `.start`, and `.stop` methods.

**Manual registration**: You can manually register a **component** in the **container** via its `#register` method, passing the component's **key**, along with either a block that returns a new **instance** of the component (which will be called whenever the component is **resolved**), or a single object (to be returned as the **instance** value whenever the component is resolved).

**Manifest registration:** You can create one or more registration manifest files, containing code that **manually registers** one or more components in the container. These files are searched during **auto-registration** to allow those components to be registered and **resolved** during both **finalization** and **lazy loading**.

**Container imports:** You can specify other containers to import into your own. The components in the imported container will be registered in your own, with a key prefix you provide. The container will be imported in full as part of **finalization**, or individual components from the container will be imported as required when **lazy loading**.

## Component loading

**Loader**: The loader is an internal facility responsible for creating the **component instances** when a component is **resolved**. Specifically, the loader will `require` the component's source file (unless **autoloading**), determine the class constant for the component, then create a new instance of the class (or the single instance of the class is a **singleton**).

**Autoloading**: When you’re using an autoloader like Zeitwerk, you can configure dry-system with the **autoloading loader**, which is a specialization of the default **loader** that does not `require` any source files, which allows the autoloader to load the component’s class constant according to its own rules.

**Memoized components**: By default, the **loader** will create a new **component instance** every time a component is **resolved**. However, you can also configure a component to be memoized (via **component dir** configuration or **magic comments**), in which case an instance is created the first time, and then reused for all subsequent resolutions.

## Container lifecycle

**Lazy loading:** Containers start in lazy loading mode, loading individual components just in time when you resolve them (as well as all the components for their dependencies, for components using **auto-injection**). This uses the same **auto-registration** process as when you **finalize** the container, ensuring your components are consistently available in both modes. Typically, you leave the container to lazy load when you want to optimize for fastest container load time, such as when running tests or during local development.

**Finalization:** When you **finalize** a container, it **imports** other containers as required, starts each of its own **providers**, then begins a one-off process to **auto-register** components for all the **source files** in its **components dirs**, as well as any components specified in registration **manifests**. Once a container is finalized, it is frozen and no additional components can be registered. Typically, you finalize a container as part of booting a long-running application process.

**Shutdown:** When you shut down a container, it runs the **stop hook** for each of its providers.

## Container configuration

**Container configuration**: You configure your container subclass via a class-level `config` object.

**Container root**: This is the path for the root of your application. All **component dirs** are expected to be under this root. For typical applications, this will be the same as the your project directory. For a minimal container setup, you should configure both the container root and at least one **component dir**.

**Component dir namespaces**: You can configure one or more namespaces within each **component dir**. Each namespace corresponds to a path within the dir, and sets configuration for loading components from the source files under that path: a **key namespace** (a prefix for the component key) and a **const namespace** (an expected Ruby constant to be used as the base namespace for the component's class constant).

**Provider paths**: You can configure one or more paths to be searched when the container loads **providers**. By default, this is a single `"system/providers/"` path only. The container will search these paths in the order specified, with the first match for a given provider name being used to load that provider.

## Extensibility

**Plugins**: You can activate additional functionality for your container by activating one or more plugins. Plugins can add additional settings and methods on your container, register their own components, and otherwise act in response to container lifecycle events (such as before/after initial configuration). When you activate a plugin, you may also pass additional options to tailor the plugin’s behavior.

**Provider packs**: You can use prebuilt providers offering useful functionality by accessing **provider packs**. These are typically distributed via 3rd party Ruby gems. When you use a provider from a provider pack, you still create your own **provider file**, but instead of specifying the provider lifecycle yourself, you instead specify a provider from a pack, and supply any required configuration for the provider. You can also enhance the provider's own lifecycle by adding your own "before" and "after" hooks for the provider lifecycle events.

## Testing

**Container stubs**: You can enable stubbing on the container to replace a particular component (via its key) for the sake of certain integration tests. You should hopefully only need this approach sparingly, since most classes designed to work well with the container (especially those using **auto-injection**) should be able to be tested in isolation using dependency injection, with particular dependencies replaced via test doubles passed to the class’ constructor.
