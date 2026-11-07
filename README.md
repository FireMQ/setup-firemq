# setup-firemq

A GitHub Action that starts a [FireMQ](https://github.com/FireMQ/firemq) broker for the rest of the job. FireMQ is a lean message broker that speaks RabbitMQ's AMQP 0-9-1, so your RabbitMQ client tests run against it unchanged.

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: FireMQ/setup-firemq@v1
  - run: npm test   # connect to amqp://guest:guest@localhost:5672
```

The broker keeps everything in memory, listens on `127.0.0.1`, and is ready when the step finishes. It runs on Linux and macOS runners, on x86-64 and ARM, and on Windows x86-64.

## Inputs

| Input | Default | Description |
|---|---|---|
| `version` | `latest` | FireMQ release to install, for example `v0.1.0`. |
| `ref` | | Build FireMQ from this commit, branch or tag instead of installing a release. The build is cached. |
| `listen` | `127.0.0.1` | Address to bind. Use `0.0.0.0` to reach the broker from job containers; the `guest` user is then allowed from any address. |
| `amqp-port` | `5672` | AMQP 0-9-1 port. |
| `fire-port` | `5673` | FireMQ protocol port. |
| `http-port` | `15672` | Management UI and API, Prometheus metrics, and WebSocket port. |
| `persistent` | `false` | Store data on disk in the runner's temp folder. |
| `args` | | Extra `firemq` flags, for example `--log debug`. |

## Outputs

| Output | Example |
|---|---|
| `amqp-url` | `amqp://guest:guest@127.0.0.1:5672` |
| `fire-url` | `fire://guest:guest@127.0.0.1:5673` |
| `ws-url` | `ws://127.0.0.1:15672/fire` |
| `http-url` | `http://127.0.0.1:15672` |
| `version` | `0.1.0` |

```yaml
  - id: firemq
    uses: FireMQ/setup-firemq@v1
    with:
      amqp-port: "5682"
  - run: pytest
    env:
      AMQP_URL: ${{ steps.firemq.outputs.amqp-url }}
```

The `firemq` command is on `PATH` in later steps, so you can declare topology or inspect queues from the job:

```yaml
  - run: firemq ctl declare-queue jobs
  - if: failure()
    run: firemq ctl list queues
```

## Using the container image instead

On Linux runners you can also run FireMQ as a service container:

```yaml
services:
  firemq:
    image: ghcr.io/firemq/firemq
    ports: ["5672:5672", "5673:5673", "15672:15672"]
```

> **Status:** `version` installs FireMQ release binaries, which exist from FireMQ v0.1.0. Until then, pass `ref` with a commit to build from source.

## License

Apache-2.0
