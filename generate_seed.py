#!/usr/bin/env python3
"""
Seed generator: Reads oxford_5000.json and generates clean SQL batch insert statements.
File generated: seed_words.sql
"""

import json
import os
import re

def escape_sql(val):
    if val is None:
        return "NULL"
    if isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, list):
        if not val:
            return "'{}'::text[]"
        escaped_items = ["'" + item.replace("\n", " ").replace("\r", " ").replace("'", "''") + "'" for item in val]
        return f"ARRAY[{', '.join(escaped_items)}]::text[]"
    if isinstance(val, dict):
        json_str = json.dumps(val, ensure_ascii=False)
        return "'" + json_str.replace("'", "''") + "'::jsonb"
    # String: normalize whitespace/newlines and escape single quotes
    s = str(val).replace("\r\n", " ").replace("\n", " ").replace("\r", " ")
    s = re.sub(r'\s+', ' ', s).strip()
    s = s.replace("'", "''")
    return f"'{s}'"

def main():
    candidate_paths = [
        os.path.join(os.path.dirname(__file__), 'assets', 'data', 'oxford_5000.json'),
        os.path.join(os.path.dirname(__file__), 'oxford_5000.json')
    ]
    json_path = next((p for p in candidate_paths if os.path.exists(p)), None)
    if not json_path:
        raise FileNotFoundError("Could not find oxford_5000.json in assets/data/ or root!")

    output_path = os.path.join(os.path.dirname(__file__), 'seed_words.sql')

    print(f"Reading {json_path}...")
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"Loaded {len(data)} items. Generating {output_path}...")

    columns = [
        "id", "word", "type", "cefr", "ielts_band", "phon_br", "phon_n_am",
        "meaning_vi", "definition", "example", "example_vi",
        "collocations", "synonyms", "antonyms", "word_family",
        "uk", "us", "topic", "subtopic"
    ]

    col_str = ", ".join(columns)

    BATCH_SIZE = 250
    items = list(data.values())

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- ==============================================================================\n")
        f.write("-- VOCAP MASTER DATA SEED SCRIPT (5,943 Oxford 5000 records)\n")
        f.write("-- ==============================================================================\n\n")
        f.write("BEGIN;\n\n")

        for i in range(0, len(items), BATCH_SIZE):
            batch = items[i:i + BATCH_SIZE]
            f.write(f"-- Batch {i // BATCH_SIZE + 1} ({len(batch)} words)\n")
            f.write(f"INSERT INTO public.words ({col_str}) VALUES\n")

            row_strs = []
            for item in batch:
                vals = [escape_sql(item.get(col)) for col in columns]
                row_strs.append(f"({', '.join(vals)})")

            f.write(",\n".join(row_strs))
            f.write("\nON CONFLICT (id) DO NOTHING;\n\n")

        # Reset sequence
        f.write("-- Reset sequence to max id\n")
        f.write("SELECT setval('words_id_seq', (SELECT MAX(id) FROM public.words));\n\n")
        f.write("COMMIT;\n")

    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"Successfully generated clean {output_path} ({size_mb:.2f} MB)!")

if __name__ == '__main__':
    main()
