import yaml
import csv
import os
from pathlib import Path


def _underscore_hex(hex: str) -> str:
    """Converts a hex value to a string with underscores every 4 characters"""
    groups = []
    while hex:
        groups.append(hex[-4:])
        hex = hex[:-4]
    groups.reverse()
    return f"0x{'_'.join(groups)}"


def _hex_to_str(val: int) -> str:
    """Formats hex to str which has 8 characters and is capitalized"""
    hex_str = f"{val:x}"
    if len(hex_str) < 8:
        hex_str = "0" * (8 - len(hex_str)) + hex_str
    return hex_str.upper()


def format_hex(val: int) -> str:
    """
    Converts a hex value to meed demands of memory map format which includes:
        * Capitalized ascii representation of the hex value
        * 0x prefix
        * Underscores every 4 characters
        * All addresses are 8 characters long
    """
    hex_str = _hex_to_str(val)
    return _underscore_hex(hex_str)


def generate_map(design: Path, output: Path):
    with open(design, "r") as f:
        data = yaml.load(f, Loader=yaml.FullLoader)
        output.parent.mkdir(exist_ok=True)
        with open(output, "w", newline="") as memory_map_csv:
            table_columns = ["Start Address", "End Address", "Size", "Type"]
            writer = csv.DictWriter(memory_map_csv, fieldnames=table_columns)
            writer.writeheader()
            subordinates_topwrap = data["design"]["interconnects"]["axi_interconnect1"]["subordinates"]
            subordinates = {
                "VeeR EL2 reserved space": {"address": 0x0, "size": 0x1FFF_FFFF}
            } | {name: list(params.values())[0] for (name, params) in subordinates_topwrap.items()}
            for peripheral, map_location in subordinates.items():
                start_address = format_hex(map_location["address"])
                end_address = format_hex(map_location["address"] + map_location["size"])
                size = format_hex(map_location["size"])
                writer.writerow(
                    {
                        table_columns[0]: start_address,
                        table_columns[1]: end_address,
                        table_columns[2]: size,
                        table_columns[3]: peripheral,
                    }
                )
            print(f"Memory map generated successfully for {design.name}")

if __name__ == "__main__":
    generate_map(
        Path("../topwrap/design-dualcore.yaml"),
        Path("build/memory_map_dualcore.csv")
    )
    generate_map(
        Path("../topwrap/design-singlecore.yaml"),
        Path("build/memory_map_singlecore.csv")
    )
