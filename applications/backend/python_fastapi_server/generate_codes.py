import uuid
import sqlite3

def generate_and_store_codes(db_path, num_codes=50):
    """Generates unique registration codes and stores them in the database."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    for _ in range(num_codes):
        code = str(uuid.uuid4())[:8]  # Use a shorter, more user-friendly code
        try:
            cursor.execute("INSERT INTO registration_codes (code) VALUES (?)", (code,))
        except sqlite3.IntegrityError:
            # This should be rare, but handle it just in case
            print(f"Code {code} already exists, generating a new one.")
            continue

    conn.commit()
    conn.close()
    print(f"{num_codes} registration codes have been generated and stored in {db_path}")

if __name__ == "__main__":
    # This assumes you're running this script from the root of the backend directory
    # and your development database is named fitness_dev.db
    generate_and_store_codes("fitness_dev.db")
