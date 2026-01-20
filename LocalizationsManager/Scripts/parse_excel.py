#!/usr/bin/env python3
"""
Excel parser using openpyxl - robust parsing for all Excel formats
Outputs JSON with localization entries
"""

import sys
import json
import subprocess

def ensure_openpyxl():
    """Ensure openpyxl is installed, install if missing"""
    try:
        import openpyxl
        return True
    except ImportError:
        print("Installing openpyxl...", file=sys.stderr)
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "--quiet", "openpyxl"])
            import openpyxl
            return True
        except Exception as e:
            print(f"Error installing openpyxl: {e}", file=sys.stderr)
            return False

def parse_excel(file_path):
    """Parse Excel file and return localization entries as JSON"""
    if not ensure_openpyxl():
        return {"error": "Failed to install openpyxl"}

    import openpyxl

    try:
        # Load workbook
        wb = openpyxl.load_workbook(file_path, read_only=True, data_only=True)
        ws = wb.active

        # Get all rows as list
        rows = list(ws.iter_rows(values_only=True))

        if not rows:
            return {"error": "Empty worksheet"}

        # First row is headers
        headers = [str(h).strip() if h else "" for h in rows[0]]

        # Find required columns
        try:
            bundle_col = headers.index("Bundle Code")
            locale_col = headers.index("Locale")
            key_col = headers.index("Text Key")
            value_col = headers.index("Text Value")
        except ValueError as e:
            missing = [col for col in ["Bundle Code", "Locale", "Text Key", "Text Value"] if col not in headers]
            return {"error": f"Missing required columns: {', '.join(missing)}"}

        # Find optional observations column
        observations_col = None
        try:
            observations_col = headers.index("Observations")
        except ValueError:
            pass  # Observations column is optional

        # Parse data rows
        entries = []
        for row in rows[1:]:
            if not row or len(row) <= max(bundle_col, locale_col, key_col, value_col):
                continue

            bundle = str(row[bundle_col]).strip() if row[bundle_col] else ""
            locale = str(row[locale_col]).strip() if row[locale_col] else ""
            key = str(row[key_col]).strip() if row[key_col] else ""
            value = str(row[value_col]).strip() if len(row) > value_col and row[value_col] else ""

            # Read observations if column exists
            comment = ""
            if observations_col is not None and len(row) > observations_col and row[observations_col]:
                comment = str(row[observations_col]).strip()

            # Skip rows without locale or key
            if not locale or not key:
                continue

            entry = {
                "bundle": bundle,
                "locale": locale,
                "key": key,
                "value": value
            }

            # Only include comment if it's not empty
            if comment:
                entry["comment"] = comment

            entries.append(entry)

        wb.close()
        return {"entries": entries}

    except Exception as e:
        return {"error": f"Failed to parse Excel: {str(e)}"}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(json.dumps({"error": "Usage: parse_excel.py <excel_file>"}))
        sys.exit(1)

    result = parse_excel(sys.argv[1])
    print(json.dumps(result, ensure_ascii=False, indent=2))
