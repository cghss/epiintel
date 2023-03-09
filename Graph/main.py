import os
import csv
from neo4j import GraphDatabase


# Pull env vars for auth and create neo4j driver
NEO4J_AUTH = (os.getenv("NEO4J_USER"), os.getenv("NEO4J_PASS"))
NEO4J_URI = os.getenv("NEO4J_URI")
NEO4J_DRIVER = GraphDatabase.driver(NEO4J_URI, auth=NEO4J_AUTH)
SESSION = NEO4J_DRIVER.session()

def get_matrix_rows():
    mrows = []
    with open("Graph/cooccurrence_matrix.csv") as matrix:
        mrows = list(csv.DictReader(matrix))
    return mrows

def get_activity_rows():
    arows = []
    with open("Graph/GOAL_metadata.csv") as activities:
        arows = list(csv.DictReader(activities))
    return arows

def create_activity_node(tx, name, functions, categories, phases):
    # Check for null value in functions and set a default value if necessary
    if not functions:
        functions = ""
    # Check for null value in categories and set a default value if necessary
    if not categories:
        categories = ""
    # Check for null value in phases and set a default value if necessary
    if not phases:
        phases = ""

    tx.run("MERGE (:Activity {name: $name, functions: $functions, "
           "categories: $categories, phases: $phases})",
           name=name, functions=functions, categories=categories, phases=phases)


# Define a function to create a relationship between activities in Neo4j
# If relationship is greater than 0...because otherwise there's 8,000+ relationships
def create_relationship(tx, act1, act2, weight):
    if weight>0.0:
        # Query for nodes with the given activity names
        tx.run("MATCH (a1:Activity {name: $act1}), (a2:Activity {name: $act2}) "
                        "CREATE (a1)-[r:CO_OCCURRENCE {weight: $weight}]->(a2) "
                        "RETURN r", act1=act1, act2=act2, weight=weight)



# Use the functions defined above to insert the co-occurrence matrix into Neo4j
with NEO4J_DRIVER.session() as session:
   # Get the activity rows
    activity_rows = get_activity_rows()

    # Create the activity nodes and add properties for each activity
    for row in activity_rows:
        activity_name = row["Activity"]
        functions = row["Function"]
        categories = row["Category"]
        phases = row["Phases"]

        session.write_transaction(create_activity_node, activity_name, functions, categories, phases)

    # Create the co-occurrence relationships   
    matrix_rows = get_matrix_rows()

    for row in matrix_rows:
        act1 = row["Act1"]
        act2 = row["Act2"]
        weight = float(row["counts"])
        
        # Create a relationship between act1 and act2 with the weight property set to the co-occurrence value, only if weight is greater than 0
        session.write_transaction(create_relationship, act1, act2, weight)

