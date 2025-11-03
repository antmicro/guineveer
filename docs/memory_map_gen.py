import yaml
import csv
import os


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


if __name__ == "__main__":
    interconnect_config_location = "../design/src/interconnect_utils/intercon_config.yaml"
    map_object = {}
    with open(interconnect_config_location, "r") as f:
        data = yaml.load(f, Loader=yaml.FullLoader)
        os.makedirs("build", exist_ok=True)
        with open("build/memory_map.csv", "w", newline="") as memory_map_csv:
            table_columns = ["Start Address", "End Address", "Size", "Type"]
            writer = csv.DictWriter(memory_map_csv, fieldnames=table_columns)
            writer.writeheader()
            slaves = {
                "VeeR EL2 reserved space": {"offset": 0x0, "size": 0x1FFF_FFFF}
            } | data["parameters"]["slaves"]
            for peripheral, map_location in slaves.items():
                start_address = format_hex(map_location["offset"])
                end_address = format_hex(map_location["offset"] + map_location["size"])
                size = format_hex(map_location["size"])
                writer.writerow(
                    {
                        table_columns[0]: start_address,
                        table_columns[1]: end_address,
                        table_columns[2]: size,
                        table_columns[3]: peripheral[0].upper() + peripheral[1:],
                    }
                )
            print("Memory map generated successfully")
