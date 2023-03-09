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

def parse_csv_string(csv_string):
    reader = csv.reader([csv_string], delimiter=',', quotechar='"')
    # convert the csv reader object to a list
    split_list = list(reader)[0]
    # strip whitespace from each item in the list
    split_list = [item.strip() for item in split_list]
    return split_list

def create_nodes(tx, activity_rows):
    for row in activity_rows:
        activity_name = row["Activity"]
        functions = row["Function"]
        categories = row["Category"]
        phases = row["Phases"]

        # Skip creating nodes that are blank
        if not functions.strip():
            continue

        if not categories.strip():
            continue

        if not phases.strip():
            continue

        tx.run("MERGE (:Activity {activity_name: $activity_name})", activity_name=activity_name)

        # Split functions, categories, and phases on commas 
        functions_list = parse_csv_string(functions)
        categories_list = parse_csv_string(categories)
        phases_list = parse_csv_string(phases)

        # Create nodes for each unique function, category, and phase
        for function_name in set(functions_list):
            tx.run("MERGE (f:Function {function_name: $function_name})", function_name=function_name)
            tx.run("MATCH (a:Activity {activity_name: $activity_name}), (f:Function {function_name: $function_name}) "
                   "MERGE (a)-[:HAS]->(f)", activity_name=activity_name, function_name=function_name)

        for category_name in set(categories_list):
            tx.run("MERGE (c:Category {category_name: $category_name})", category_name=category_name)
            tx.run("MATCH (a:Activity {activity_name: $activity_name}), (c:Category {category_name: $category_name}) "
                   "MERGE (a)-[:HAS]->(c)", activity_name=activity_name, category_name=category_name)

        for phase_name in set(phases_list):
            tx.run("MERGE (p:Phase {phase_name: $phase_name})", phase_name=phase_name)
            tx.run("MATCH (a:Activity {activity_name: $activity_name}), (p:Phase {phase_name: $phase_name}) "
                   "MERGE (a)-[:HAS]->(p)", activity_name=activity_name, phase_name=phase_name)

# Define a function to create a relationship between activities in Neo4j
# If relationship is greater than 0...because otherwise there's 8,000+ relationships
def create_relationship(tx, act1, act2, weight):
    if weight>0.0:
        # Query for nodes with the given activity names
        tx.run("MATCH (a1:Activity {activity_name: $act1}), (a2:Activity {activity_name: $act2}) "
                        "CREATE (a1)-[r:CO_OCCURRENCE {weight: $weight}]->(a2) "
                        "RETURN r", act1=act1, act2=act2, weight=weight)



# Use the functions defined above to insert the co-occurrence matrix into Neo4j
with NEO4J_DRIVER.session() as session:

    session.write_transaction(create_nodes, get_activity_rows())

    # Create the co-occurrence relationships   
    matrix_rows = get_matrix_rows()

    for row in matrix_rows:
        act1 = row["Act1"]
        act2 = row["Act2"]
        weight = float(row["counts"])
        
        # Create a relationship between act1 and act2 with the weight property set to the co-occurrence value, only if weight is greater than 0
        session.write_transaction(create_relationship, act1, act2, weight)

