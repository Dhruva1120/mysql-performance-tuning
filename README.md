# MySQL Query Performance Tuning

A hands-on project demonstrating query optimization techniques using MySQL's EXPLAIN execution plan. Built a 10-table e-commerce schema, generated 900,000+ rows using stored procedures, and resolved 6 real-world performance bottlenecks.

---

## Schema

10 tables modelling a simplified e-commerce system:

```
customers → orders → order_items → products → categories
                  → payments
                  → shipments
         → reviews
coupons  → coupon_usage
```

---

## Results

| Problem | Technique | Before | After |
|---|---|---|---|
| Full scan on email column | Added B-Tree index | 800ms | 2ms |
| Missing FK index on orders | Added index on `customer_id` | 4.2s | 0.8ms |
| Correlated subquery in revenue report | Rewrote as aggregated LEFT JOIN | 18 min | 6s |
| `YEAR()`/`MONTH()` on date column | Rewrote as range predicate | 8s | 210ms |
| 5-table JOIN with no indexes | Composite index on `(status, order_date)` | 12 min | 4s |
| `SELECT *` on product listing | Covering index | 620ms | 18ms |

---

## Key Concepts

**EXPLAIN** — MySQL's tool to show how a query will be executed. The two most important columns:
- `type` — how MySQL reads the table. `ALL` means full scan (bad). `ref` or `eq_ref` means index lookup (good).
- `rows` — how many rows MySQL estimates it must examine. Tuning is about making this number smaller.

**Indexes** — Allow MySQL to jump directly to matching rows instead of scanning the entire table. Like a book's index — you go straight to the page instead of reading every page.

**Covering index** — An index that includes every column a query needs. MySQL answers the query from the index alone with zero table row reads. EXPLAIN shows `Using index` in the Extra column.

**Correlated subquery** — A subquery that runs once per row of the outer query. EXPLAIN shows `DEPENDENT SUBQUERY`. With large tables this is catastrophic — rewriting as a `LEFT JOIN` with `GROUP BY` fixes it.

---

## How to Run

```bash
# 1. Create schema
mysql -u root -p < 01_schema.sql

# 2. Populate data (~2-3 minutes)
mysql -u root -p < 02_populate.sql

# 3. Run tuning analysis
mysql -u root -p < 03_tuning.sql
```

For each problem in `03_tuning.sql`, run the BEFORE `EXPLAIN`, note the `rows` and `type` values, apply the fix, then run the AFTER `EXPLAIN` to see the improvement.

---

## Tools
MySQL 8.0 · DataGrip
