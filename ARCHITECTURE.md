# Architecture

### Setup

```
 setup(opts) ─────────► config.setup(opts)
                         - extend config options
                                │
                                ▼
                        store.setup(opts)
                         - check if current dir has cache file
                         - missing? create

```

