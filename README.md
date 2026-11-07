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
  01-webhook-hmac/    code, tests, README.md, before.txt, after.txt
  02-webhook-replay/
  _template/          README.md, go.mod, main.go, main_test.go
  README.md
  Makefile
  compose.yaml
  .gitignore
```

-   **name:** `NN-topic-subject`, lowercase, with hyphens. the number is given when the folder is created, in the order the experiments are done, and never changes. topic prefixes: `webhook-`, `http-`, `oauth-`, `pg-`, `stock-`, `prod-`.
-   **self-contained:** each folder has its own code, tests, a `README.md` copied from `_template/README.md`, and its measurement results (`before.txt`, `after.txt`, `load.txt`), all at the same level. a go experiment is its own module (`go.mod`), a bun experiment has its own `package.json`, and a sql experiment has only `.sql` files. there is no root `go.mod`.
-   **flat:** no topic folders, no `results/` folder. the only non-experiment folder is `_template/`: the `_` prefix keeps it first in listings, and go and `make test` skip it.
-   **minimal:** only what the question needs. standard library first; dependencies only when the experiment is about them.
-   an experiment that grows into a tool moves to its own repository.

start a new experiment:

```sh
# Go: copy the whole skeleton and rename the module
cp -R _template NN-topic-subject && cd NN-topic-subject
go mod edit -module github.com/abneribeiro/experiments/NN-topic-subject

# Bun or SQL: copy only the README
mkdir NN-topic-subject && cp _template/README.md NN-topic-subject/ && cd NN-topic-subject
bun init -y                                                       # Bun only
```

## **run**

```sh
make db-up                          # start PostgreSQL 18 and wait until it is healthy
make db-down                        # stop it and delete all data
make psql                           # open psql in the container
make test                           # go test -race in every Go experiment
make test DIR=01-webhook-hmac       # ...or in one
make run DIR=01-webhook-hmac        # go run the experiment
make bench DIR=01-webhook-hmac      # benchmarks, -count=10, saved to before.txt
make bench DIR=01-webhook-hmac NAME=after   # ...saved to after.txt
make compare DIR=01-webhook-hmac    # benchstat before.txt after.txt
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
