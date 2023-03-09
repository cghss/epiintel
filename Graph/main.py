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
    name = name.replace('"','')
    tx.run("MERGE (:Activity {name: $name})", name=name)

# Define a function to create a relationship between activities in Neo4j
# If relationship is greater than 0...because otherwise there's 8,000+ relationships
def create_relationship(tx, act1, act2, weight):
    if weight > 0.0:
        tx.run("MATCH (n1:Activity {name: $act1}), (n2:Activity {name: $act2}) "
               "CREATE (n1)-[:CO_OCCURS_WITH {weight: $weight}]->(n2)", 
               act1=act1, act2=act2, weight=weight)

# Use the functions defined above to insert the co-occurrence matrix into Neo4j
with NEO4J_DRIVER.session() as session:
    matrix_rows = get_rows()

    for row in matrix_rows:
        act1 = row["Act1"]
        act2 = row["Act2"]
        weight = float(row["counts"])
        
        # Create nodes for act1 and act2 if they don't exist already
        session.write_transaction(create_node, act1)
        session.write_transaction(create_node, act2)
        
        # Create a relationship between act1 and act2 with the weight property set to the co-occurrence value, only if weight is greater than 0
        session.write_transaction(create_relationship, act1, act2, weight)

