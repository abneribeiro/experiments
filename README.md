<div align="center">
  <br />
  <h3><b>experiments</b></h3>
  <p>small, deep experiments in go, typescript and postgres. each one answers a single question with a measurement and a short write-up.</p>
</div>

<br />

## **index**

| # | question | stack | result |
|---|----------|-------|--------|

## **layout**

one flat folder per experiment, at the root:

```
experiments/
  01-webhook-hmac/    code, tests, README.md, NOTES.md, before.txt, after.txt
  02-webhook-replay/
  _template/          README.md, NOTES.md, go.mod, main.go, main_test.go
  _template-ts/       package.json, bun.lock, tsconfig.json, index.ts, index.test.ts, bench.ts
  README.md
  Makefile
  compose.yaml
  .gitignore
```

-   **name:** `NN-topic-subject`, lowercase, with hyphens. the number is given when the folder is created, in the order the experiments are done, and never changes. topic prefixes: `webhook-`, `http-`, `oauth-`, `pg-`, `stock-`, `prod-`, `ts-`.
-   **self-contained:** each folder has its own code, tests, a `README.md` and a `NOTES.md` copied from `_template/`, and its measurement results (`before.txt`, `after.txt`, `load.txt`), all at the same level. a go experiment is its own module (`go.mod`), a bun experiment has its own `package.json`, and a sql experiment has only `.sql` files. there is no root `go.mod`.
-   **notes vs readme:** `NOTES.md` is the loose log written while studying (sources, sessions, questions, dead ends); `README.md` is the clean result written at the end.
-   **flat:** no topic folders, no `results/` folder. the only non-experiment folders are `_template/` (go, plus the readme and notes every experiment gets) and `_template-ts/` (bun): the `_` prefix keeps them first in listings, and go and `make test` skip them.
-   **minimal:** only what the question needs. standard library first; dependencies only when the experiment is about them.
-   an experiment that grows into a tool moves to its own repository.

start a new experiment:

```sh
make new DIR=01-webhook-hmac              # go: copies _template/, renames the module
make new DIR=02-ts-webhook-hmac KIND=ts   # bun: strict tsconfig, bun test, mitata
make new DIR=05-pg-isolation KIND=sql     # sql: readme and notes only
```

an experiment is done when every box in its readme's "done when" list is ticked.

## **run**

```sh
make db-up                          # start PostgreSQL 18 and wait until it is healthy
make db-down                        # stop it and delete all data
make psql                           # open psql in the container
make test                           # every experiment: go test -race, or bun test + tsc --noEmit
make test DIR=01-webhook-hmac       # ...or in one
make run DIR=01-webhook-hmac        # go run, or bun run index.ts
make bench DIR=01-webhook-hmac      # go: -count=10; bun: mitata; saved to before.txt
make bench DIR=01-webhook-hmac NAME=after   # ...saved to after.txt
make compare DIR=01-webhook-hmac    # go: benchstat; bun: side by side
```

the makefile exports `DATABASE_URL` (`postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable`). outside `make`, export it by hand. bun and sql experiments list their exact commands in their own readme.

## **measure**

| question | how |
|----------|-----|
| faster or lighter? | `make bench` before and after the change, then `make compare` (ns/op, B/op, allocs/op). |
| safe under concurrency? | `make test`, which runs the race detector. |
| how does an endpoint hold up under load? | vegeta at a fixed rate; read p50, p95 and p99. |
| what does a query do? | `EXPLAIN (ANALYZE, BUFFERS)` in `make psql`, with realistic data. |
| where does the cpu go? | pprof. |
| is it correct? | a count: the same webhook sent 100 times gives 1 row. |
| bun: faster or correct? | `bun test`; benchmarks with `mitata`, output saved to `before.txt` / `after.txt`. |
| does a type rule hold? | `make test`, which runs `tsc --noEmit`; a line marked `@ts-expect-error` must fail to compile. |

before any benchmark, so before and after are comparable:

-   on power, heavy apps closed, nothing else running
-   the same machine and the same data for before and after
-   go: `-count=10`, and only trust a change that `benchstat` marks significant

load test with vegeta (keep `load.bin` locally, commit `load.txt`):

```sh
echo "GET http://localhost:8080/items" \
  | vegeta attack -rate=500 -duration=30s \
  | tee 01-webhook-hmac/load.bin \
  | vegeta report > 01-webhook-hmac/load.txt
```

cpu profile with pprof:

```sh
cd 01-webhook-hmac
go test -run='^$' -bench=. -cpuprofile cpu.prof
go tool pprof -http=:8081 cpu.prof
```

tools:

```sh
brew install vegeta
go install golang.org/x/perf/cmd/benchstat@latest
```

## **license**

-   [mit](LICENSE)
