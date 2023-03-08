import os
import csv
from neo4j import GraphDatabase


# Pull env vars for auth and create neo4j driver
NEO4J_AUTH = (os.getenv("NEO4J_USER"), os.getenv("NEO4J_PASS"))
NEO4J_URI = os.getenv("NEO4J_URI")
NEO4J_DRIVER = GraphDatabase.driver(NEO4J_URI, auth=NEO4J_AUTH)
SESSION = NEO4J_DRIVER.session()

def get_rows():
    rows = []
    with open("Graph/cooccurrence_matrix.csv") as matrix:
        rows = list(csv.DictReader(matrix))
    return rows

def create_node(tx, name):
    tx.run("MERGE (:Node {name: $name})", name=name)

# Define a function to create a relationship in Neo4j
def create_relationship(tx, node1, node2, weight):
    if weight > 0.0:
        tx.run("MATCH (n1:Node {name: $node1}), (n2:Node {name: $node2}) "
               "CREATE (n1)-[:CO_OCCURS_WITH {weight: $weight}]->(n2)", 
               node1=node1, node2=node2, weight=weight)

# Use the functions defined above to insert the co-occurrence matrix into Neo4j
with NEO4J_DRIVER.session() as session:
    matrix_rows = get_rows()

    for row in matrix_rows:
        node1 = row["Act1"]
        node2 = row["Act2"]
        weight = float(row["counts"])
        
        # Create nodes for node1 and node2 if they don't exist already
        session.write_transaction(create_node, node1)
        session.write_transaction(create_node, node2)
        
        # Create a relationship between node1 and node2 with the weight property set to the co-occurrence value, only if weight is greater than 0
        session.write_transaction(create_relationship, node1, node2, weight)

