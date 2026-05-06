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


def convert(input_path: str, output_path: str) -> None:
    with open(input_path) as f:
        data = json.load(f)

    coverage = Element("coverage", version="1")

    for file_entry in data.get("files", []):
        file_path = file_entry.get("path", "")
        # Make path relative to repo root
        try:
            rel_path = str(Path(file_path).relative_to(Path.cwd()))
        except ValueError:
            rel_path = file_path

        file_elem = SubElement(coverage, "file", path=rel_path)

        for line in file_entry.get("functions", []):
            for line_num in range(
                line.get("lineNumber", 0),
                line.get("lineNumber", 0) + line.get("lineCount", 1),
            ):
                if line_num > 0:
                    SubElement(
                        file_elem,
                        "lineToCover",
                        lineNumber=str(line_num),
                        covered=str(line.get("executionCount", 0) > 0).lower(),
                    )

    xml_str = parseString(tostring(coverage)).toprettyxml(indent="  ")
    with open(output_path, "w") as f:
        f.write(xml_str)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.json> <output.xml>")
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])
