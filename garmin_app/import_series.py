#!/usr/bin/env python3
import json
import glob
import os

def format_move(m):
    name = m.get("name", "Unknown")
    side = m.get("side", "")
    counter = m.get("counter_name", "")

    if side and side in ["L", "R", "mid"]:
        name = f"{name} {side}"

    if counter:
        c_side = m.get("counter_side", "")
        if c_side and c_side in ["L", "R", "mid"]:
            counter = f"{counter} {c_side}"
        return f"{name} -> {counter}"

    return name

def parse_series(series_data):
    title = series_data.get("title", "Unknown Series")
    moves_list = series_data.get("moves", [])

    combos = []
    for m in moves_list:
        sub_moves_json = m.get("sub_moves_json")
        chain_json = m.get("chain_json")
        if sub_moves_json:
            try:
                sub_moves = json.loads(sub_moves_json)
                combos.append(" + ".join([format_move(sm) for sm in sub_moves]))
            except:
                combos.append(format_move(m))
        elif chain_json:
            try:
                chain_moves = json.loads(chain_json)
                combos.append(" -> ".join([format_move(cm) for cm in chain_moves]))
            except:
                combos.append(format_move(m))
        else:
            combos.append(format_move(m))

    return {"title": title, "combos": combos}

def parse_series_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
        if not isinstance(data, list) or len(data) == 0:
            return []

        return [parse_series(s) for s in data if isinstance(s, dict)]

def main():
    # Assets are now located in the root assets/ directory
    json_files = glob.glob("../assets/jkd-series-*.json")
    all_series = []
    
    if not json_files:
        print("No series files found in ../assets/")
        return

    print(f"Found {len(json_files)} series files.")
    for f in sorted(json_files):
        print(f"Parsing {f}...")
        for s in parse_series_file(f):
            all_series.append(s)

    mc_content = """module JKDSeries {
    class Series {
        var title as $.Toybox.Lang.String;
        var combos as $.Toybox.Lang.Array<$.Toybox.Lang.String>;

        function initialize(t as $.Toybox.Lang.String, c as $.Toybox.Lang.Array<$.Toybox.Lang.String>) {
            title = t;
            combos = c;
        }
    }

    function getSeries() as $.Toybox.Lang.Array<Series> {
        return [
"""
    
    series_entries = []
    for s in all_series:
        combos_fmt = ",\n                ".join([f'"{c}"' for c in s['combos']])
        entry = f"""            new Series("{s['title']}", [
                {combos_fmt}
            ])"""
        series_entries.append(entry)
        
    mc_content += ",\n".join(series_entries)
    mc_content += """
        ];
    }
}
"""

    with open("JKDApp/source/JKDSeries.mc", "w", encoding="utf-8") as f:
        f.write(mc_content)
    
    print("Successfully generated JKDApp/source/JKDSeries.mc (Single Language Data)")

if __name__ == "__main__":
    main()
