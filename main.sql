CREATE TABLE edges (
  id SERIAL PRIMARY KEY,
  source_node INTEGER NOT NULL,
  destination_node INTEGER NOT NULL
);

CREATE TABLE nodes (
  id SERIAL PRIMARY KEY,
  value TEXT NOT NULL
);

INSERT INTO nodes (value) VALUES ('A'), ('B'), ('C'), ('D'), ('E');

INSERT INTO edges (source_node, destination_node) VALUES
  (1, 2),
  (1, 3),
  (2, 4),
  (3, 4),
  (4, 5);

WITH RECURSIVE traversal AS (
  SELECT e.source_node, e.destination_node, 1 AS level
  FROM edges e
  WHERE e.source_node = 1
  UNION ALL
  SELECT e.source_node, e.destination_node, t.level + 1
  FROM edges e
  JOIN traversal t ON e.source_node = t.destination_node
)
SELECT n.value, t.level
FROM traversal t
JOIN nodes n ON t.destination_node = n.id; 

CREATE OR REPLACE FUNCTION get_shortest_path(source INTEGER, destination INTEGER)
RETURNS TABLE (path TEXT[]) AS $$
BEGIN
  RETURN QUERY WITH RECURSIVE traversal AS (
    SELECT e.source_node, e.destination_node, ARRAY[e.source_node] AS path, 1 AS level
    FROM edges e
    WHERE e.source_node = source
    UNION ALL
    SELECT e.source_node, e.destination_node, t.path || e.destination_node, t.level + 1
    FROM edges e
    JOIN traversal t ON e.source_node = t.destination_node
  )
  SELECT t.path
  FROM traversal t
  WHERE t.destination_node = destination AND t.level = (SELECT MIN(level) FROM traversal WHERE destination_node = destination);
END; $$ LANGUAGE plpgsql;

SELECT * FROM get_shortest_path(1, 5);

WITH RECURSIVE connected_components AS (
  SELECT id, id AS component_id, 1 AS level
  FROM nodes
  UNION ALL
  SELECT n.id, cc.component_id, cc.level + 1
  FROM nodes n
  JOIN edges e ON n.id = e.source_node
  JOIN connected_components cc ON e.destination_node = cc.id
)
SELECT component_id, COUNT(*) AS node_count
FROM connected_components
GROUP BY component_id
ORDER BY node_count DESC;

CREATE OR REPLACE FUNCTION get_node_degree(node_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
  degree INTEGER;
BEGIN
  SELECT COUNT(*) INTO degree
  FROM edges
  WHERE source_node = node_id OR destination_node = node_id;
  RETURN degree;
END; $$ LANGUAGE plpgsql;

SELECT n.id, n.value, get_node_degree(n.id) AS degree
FROM nodes n
ORDER BY degree DESC;
