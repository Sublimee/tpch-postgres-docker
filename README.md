# TPC-H PostgreSQL Docker Image

Docker image with **PostgreSQL** preloaded with **TPC-H benchmark** data for analytics and performance testing.

Includes:
- PostgreSQL 17
- CSV data generated from `dbgen` (TPC-H kit ver 3.0.1 originally from [official website](https://www.tpc.org/tpc_documents_current_versions/current_specifications5.asp) with [modified makefile](modified-makefile))
- Automatic loading of schema (no foreign keys provided) & data at container startup

## 📦 What is TPC-H?
[TPC-H](http://www.tpc.org/tpch/) is an industry-standard decision support benchmark.  
It consists of a suite of business-oriented ad-hoc queries and concurrent data modifications.

This image is useful for:
- Testing analytics query performance
- Benchmarking PostgreSQL
- Query optimization experiments
- Learning SQL with realistic data

---

## 🚀 Build

Clone this repository:

```bash
git clone https://github.com/Sublimee/tpch-postgres-docker.git
cd tpch-postgres-docker
```

Build the image (default scale factor = 0.1 GB):

```bash
docker build -t tpch-postgres .
```

Or set a different scale factor:

```bash
docker build -t tpch-postgres --build-arg SCALE_FACTOR=1 .
```

## ▶️ Run

Start the container:

```bash
docker run -d \
    --name tpch \
    -p 5432:5432 \
    -e POSTGRES_DB=tpch \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    tpch-postgres
```

Connect with psql:

```bash
psql -h localhost -p 5432 -U postgres -d tpch
```

## 📂 Database Schema

List all tables:

```bash
\dt
```

Describe a table:

```bash
\d orders
```

## 📊 Example Query

```sql
SELECT l_returnflag, l_linestatus,
       SUM(l_quantity) AS sum_qty,
       SUM(l_extendedprice) AS sum_base_price,
       SUM(l_extendedprice * (1 - l_discount)) AS sum_disc_price,
       SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge,
       AVG(l_quantity) AS avg_qty,
       AVG(l_extendedprice) AS avg_price,
       AVG(l_discount) AS avg_disc,
       COUNT(*) AS count_order
FROM lineitem
WHERE l_shipdate <= DATE '1998-12-01' - INTERVAL '90 day'
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;

```