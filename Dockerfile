# ---------- Stage 1: build & generate TPC-H data ----------
FROM alpine:3.22.1 AS tpch-builder

ARG SCALE_FACTOR=0.1
ENV SCALE_FACTOR=${SCALE_FACTOR}

# install deps
RUN apk add --no-cache build-base bash coreutils

WORKDIR /src/tpch

# copy tpch-kit (dbgen)
COPY ["TPC-H V3.0.1/", "/src/tpch/"]

WORKDIR /src/tpch/dbgen

COPY modified-makefile makefile

## build dbgen
RUN make -j"$(nproc)"

# generate .tbl and convert to .csv
RUN mkdir -p /out \
  && ./dbgen -vf -s ${SCALE_FACTOR} \
  && for f in *.tbl; do \
      sed 's/|$//' "$f" > "/out/${f%.tbl}.csv"; \
     done \
  && rm -f *.tbl

## produce a postgres-friendly DDL from original schema
RUN awk '1' /src/tpch/dbgen/dss.ddl \
  | sed \
    -e "s/TYPE =/ /g" \
    -e "s/INTEGER/INT/g" \
    -e "s/DECIMAL(/NUMERIC(/g" \
    > /out/dss_postgres.ddl

## ---------- Stage 2: Postgres with preloaded TPC-H ----------
FROM postgres:17.6

ENV POSTGRES_DB=tpch
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

# place data & init scripts
COPY --from=tpch-builder /out/*.csv /tpch-data/
COPY --from=tpch-builder /out/dss_postgres.ddl /docker-entrypoint-initdb.d/01_schema.sql

# load data script
COPY <<'SQL' /docker-entrypoint-initdb.d/02_load.sql
\set ON_ERROR_STOP on
\echo 'Loading TPC-H CSV into Postgres...'

\copy nation   from '/tpch-data/nation.csv'   with (format csv, delimiter '|', header false);
\copy region   from '/tpch-data/region.csv'   with (format csv, delimiter '|', header false);
\copy part     from '/tpch-data/part.csv'     with (format csv, delimiter '|', header false);
\copy supplier from '/tpch-data/supplier.csv' with (format csv, delimiter '|', header false);
\copy partsupp from '/tpch-data/partsupp.csv' with (format csv, delimiter '|', header false);
\copy customer from '/tpch-data/customer.csv' with (format csv, delimiter '|', header false);
\copy orders   from '/tpch-data/orders.csv'   with (format csv, delimiter '|', header false);
\copy lineitem from '/tpch-data/lineitem.csv' with (format csv, delimiter '|', header false);

ANALYZE;
\echo 'TPC-H load complete.'
SQL