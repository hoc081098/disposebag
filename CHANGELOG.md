## 1.5.0-nullsafety.0 - Dec 11, 2020

-   Migrate this package to null safety.
-   Sdk constraints: `>=2.12.0-0 <3.0.0` based on beta release guidelines.

## 1.4.0 - Nov 25, 2020

-   **Breaking change**: custom logger via static variable `DisposeBag.logger`. It can be set to `null` to disable logging.
-   Refactor: performance optimization.

## 1.3.2 - Nov 18, 2020

-   Fix: `The method 'mapIndexed' is defined in multiple extensions for 'Set<dynamic>' and neither is more specific.` when using `collection: 1.15.0-nullsafety.5` package.

## 1.3.1 - Oct 6, 2020

-   Add extension for `Iterable<Sink>` and `Iterable<StreamSubscription>`.
-   Update docs.

## 1.3.0 - Sep 29, 2020

-   Bugfix: `Uncaught Error: Bad state: Cannot add event after closing`.

## 1.2.0 - Aug 15, 2020

-   Updated: `constructor` allow only **`Sink | StreamSubscription`** type.

## 1.1.4 - Aug 15, 2020

-   Updated: methods `add`, `addAll`, `remove` and `delete` allow only **`Sink | StreamSubscription`** type.
-   Updated: internal implementation.
-   Fixed: default logger logs `error` and `StackTrace` to console, before missing.

## 1.1.3 - Aug 4, 2020

-   Updated: `README.md`.

-   Breaking change: Change `Logger`'s signature.
    The `clear` and `dispose` methods now returns a `Future<bool>` instead of `Future<void>`.

## 1.1.2 - Apr 11, 2020

-   Add `disposedBy` extension method for `StreamSubscription`
-   Add `disposedBy` extension method for `Sink`

## 1.1.1+1 - Jan 26, 2020

-   Update `logger`

## 1.1.1 - Jan 22, 2020

-   Fix `collection` version

## 1.1.0 - Jan 22, 2020

-   Add `logger` that logs disposed resources
-   Minors update
-   Upgrade min sdk to `2.6.0`

## 1.0.0+1 - Nov 9, 2019

-   Minors update

## 1.0.0 - Aug 14, 2019

-   Minors update
-   Add tests

## 0.0.9

-   Initial version, created by Stagehand
