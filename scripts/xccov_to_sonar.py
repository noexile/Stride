#!/usr/bin/env python3
"""
Converts xccov JSON output to SonarCloud generic test coverage XML.

Usage: python3 scripts/xccov_to_sonar.py coverage.json sonar-coverage.xml

SonarCloud generic format:
  https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/test-coverage/generic-test-data/
"""

import json
import sys
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom.minidom import parseString


def file_entries(data):
    """
    xccov --files-for-target --json returns a top-level list of file objects.
    xccov --report --json returns a dict with a 'targets' or 'files' key.
    Handle both.
    """
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        # --report format: { "targets": [{ "files": [...] }] }
        if "targets" in data:
            entries = []
            for target in data["targets"]:
                entries.extend(target.get("files", []))
            return entries
        return data.get("files", [])
    return []


def convert(input_path: str, output_path: str) -> None:
    with open(input_path) as f:
        data = json.load(f)

    coverage = Element("coverage", version="1")

    for file_entry in file_entries(data):
        file_path = file_entry.get("path", "")
        try:
            rel_path = str(Path(file_path).relative_to(Path.cwd()))
        except ValueError:
            rel_path = file_path

        file_elem = SubElement(coverage, "file", path=rel_path)

        for line in file_entry.get("functions", []):
            start = line.get("lineNumber", 0)
            count = line.get("lineCount", 1)
            executed = line.get("executionCount", 0) > 0
            for line_num in range(start, start + count):
                if line_num > 0:
                    SubElement(
                        file_elem,
                        "lineToCover",
                        lineNumber=str(line_num),
                        covered=str(executed).lower(),
                    )

    xml_str = parseString(tostring(coverage)).toprettyxml(indent="  ")
    with open(output_path, "w") as f:
        f.write(xml_str)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.json> <output.xml>")
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])
