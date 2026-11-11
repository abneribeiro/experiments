<div align="center">
  <br />
<h3><b>01 · pg-pagination</b></h3>
<p>when does loading every product at once stop being cheaper than paginating, and which pagination survives deep pages?</p>
</div>

<br />

## **hypothesis**

<!-- yours, before measuring. write a guess with numbers:
     at how many rows does "load all" lose? how much slower is the
     last page with offset than the first? and why you think so. -->

## **setup**

-   machine: macbook air m5, 16 gb, on power, heavy apps closed; all variants on the same machine
-   stack: go 1.x, net/http, pgx
-   database: postgresql 18 from `compose.yaml`
-   data: `products(id, name, price, created_at)`, generated with `generate_series`, at 1 000, 10 000, 100 000 and 1 000 000 rows; index on `(created_at, id)`
-   note: at these sizes the whole table fits in memory

## **run**

```sh
# exact commands to reproduce the results
```

## **results**

speed, page size 50:

| rows      | variant  | page   | query ms | p50 ms | p99 ms | response bytes |
|-----------|----------|--------|----------|--------|--------|----------------|
| 1 000     | all      | -      |          |        |        |                |
| 1 000     | offset   | first  |          |        |        |                |
| 1 000     | offset   | last   |          |        |        |                |
| 1 000     | keyset   | first  |          |        |        |                |
| 1 000     | keyset   | last   |          |        |        |                |

(repeat for 10 000, 100 000 and 1 000 000)

correctness, walking every page while rows are inserted:

| variant | duplicated items | skipped items |
|---------|------------------|---------------|
| offset  |                  |               |
| keyset  |                  |               |

raw output: `all.txt`, `offset.txt`, `keyset.txt`, `explain.txt`

## **what i learned**

<!-- yours. one sentence. -->

## **done when**

-   [ ] the question has an answer, with a number: the row count where "load all" loses
-   [ ] `make test DIR=01-pg-pagination` passes
-   [ ] the raw measurements are committed (`all.txt`, `offset.txt`, `keyset.txt`, `explain.txt`)
-   [ ] i explained the solution without looking (`NOTES.md`)
-   [ ] its row in the root index is filled in

## **links**

-   article:
-   posts: