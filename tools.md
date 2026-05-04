# Tools

## code-review-graph

SQLite code graph at `.code-review-graph/graph.db`. Use instead of grep/find to navigate the codebase with far fewer tokens.

### Schema

**nodes** — every symbol in the codebase
| column | meaning |
|--------|---------|
| `kind` | `File`, `Class`, `Function`, `Method`, etc. |
| `name` | short name (`AuthNotifier`) |
| `qualified_name` | fully qualified (`AuthNotifier.checkSession`) |
| `file_path` | absolute path |
| `line_start` / `line_end` | line range |
| `community_id` | logical cluster ID |

**edges** — relationships between symbols
| column | meaning |
|--------|---------|
| `kind` | `calls`, `imports`, `extends`, `implements`, etc. |
| `source_qualified` | caller / dependent |
| `target_qualified` | callee / dependency |
| `confidence` | 0.0–1.0 |

### Useful queries

```bash
DB=/home/tawsif/Documents/digital-card-flutter/.code-review-graph/graph.db

# Find a class/function by name
sqlite3 $DB "SELECT kind, name, file_path, line_start FROM nodes WHERE name LIKE '%AuthNotifier%';"

# All functions in a file
sqlite3 $DB "SELECT kind, name, line_start FROM nodes WHERE file_path LIKE '%auth_provider%' ORDER BY line_start;"

# What does X call?
sqlite3 $DB "SELECT target_qualified, kind FROM edges WHERE source_qualified LIKE '%checkSession%';"

# What calls X?
sqlite3 $DB "SELECT source_qualified, kind FROM edges WHERE target_qualified LIKE '%checkSession%';"

# All imports of a file
sqlite3 $DB "SELECT source_qualified FROM edges WHERE kind='imports' AND target_qualified LIKE '%color_utils%';"

# Files in a community cluster (related code)
sqlite3 $DB "SELECT DISTINCT file_path FROM nodes WHERE community_id = (SELECT community_id FROM nodes WHERE name='AuthNotifier' LIMIT 1);"

# Full-text search across all symbols
sqlite3 $DB "SELECT name, file_path, line_start FROM nodes_fts WHERE nodes_fts MATCH 'cardBuilder' LIMIT 20;"

# High-risk nodes (change impact)
sqlite3 $DB "SELECT n.name, n.file_path, r.score FROM risk_index r JOIN nodes n ON r.node_id = n.id ORDER BY r.score DESC LIMIT 10;" 2>/dev/null || true
```

### When to use

- Locating where a symbol is defined → query `nodes` by `name`
- Tracing call chains → traverse `edges`
- Understanding what a file imports → query `edges` with `kind='imports'`
- Finding all callers of a function before refactoring → reverse edge lookup
- Exploring a feature cluster → query by `community_id`

### Rebuilding the graph

If files change significantly, rebuild the graph so queries stay accurate (check the tool's own docs for the rebuild command).
