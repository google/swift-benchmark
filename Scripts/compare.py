import sys
import json
from pprint import pprint
from collections import defaultdict


def fail(msg):
    raise Exception(msg)


def require(cond, msg):
    if not cond:
        fail(msg)


def validate(file_name, parsed):
    require("benchmarks" in parsed, 
            "{}: missing key 'benchmarks'.".format(file_name))
    require(len(parsed["benchmarks"]) > 0, 
            "{}: must have at least one benchmark.".format(file_name))

    for i, benchmark in enumerate(parsed["benchmarks"]):
        require("name" in benchmark,
                "{}: benchmark #{}: missing key 'name'.".format(file_name, i))

        for k, v in benchmark.items():
            if k != "name":
                is_num = isinstance(v, int) or isinstance(v, float)
                template = "{}: benchmark #{}: values must be numbers."
                require(is_num, template.format(file_name, i))


def parse_and_validate(file_names):
    if len(file_names) < 2:
        fail("must provide two or more files to compare.") 

    runs = []

    for file_name in file_names:
        with open(file_name) as f:
            parsed = None
            try:
                parsed = json.load(f)
            except Exception as err:
                fail("failed to parse json: {}".format(err))
            validate(file_name, parsed)
            runs.append((file_name, parsed))

    return runs


def extract_values(runs):
    baseline_name, baseline = runs[0]

    confs = []
    values = {}

    for benchmark in baseline["benchmarks"]:
        benchmark_name = benchmark["name"]
        for column in benchmark.keys():
            if column == "name":
                continue
            conf = (benchmark_name, column)
            confs.append(conf)
            values[conf] = {}

    for conf in confs:
        bench_name, column = conf
        for (file_name, run) in runs:
            for bench in run["benchmarks"]:
                if bench["name"] == bench_name:
                    values[conf][file_name] = bench[column]

    return (confs, values)


def to_table(confs, file_names, values):
    baseline_file_name = file_names[0]
    rows = [] 

    # Header row.
    header = []
    header.append("benchmark")
    header.append("column")
    for (n, file_name) in enumerate(file_names):
        name = file_name.replace(".json", "")
        header.append(name)
        if n != 0:
            header.append("%")
    rows.append(header)

    # Body rows.
    for conf in confs:
        bench_name, column = conf
        row = []
        row.append(bench_name)
        row.append(column)
        for n, file_name in enumerate(file_names):
            base_value = values[conf][baseline_file_name]
            value = values[conf][file_name]
            row.append("{:.2f}".format(value))
            if n != 0:
                relative = value/base_value
                relative_percentage = (1 - relative ) * 100
                row.append("{:.2f}".format(relative_percentage))
        rows.append(row)

    return rows


def pad(base, fill, count, right = False):
    while len(base) < count:
        if right:
            base += fill
        else:
            base = fill + base
    return base


def print_table(table):
    widths = defaultdict(lambda: 0)
    for row in table:
        for ncol, col in enumerate(row):
            widths[ncol] = max(widths[ncol], len(str(col)))

    for nrow, row in enumerate(table):
        line = []
        for ncol, col in enumerate(row):
            right = ncol == 0 or ncol == 1
            line.append(pad(str(col), " ", widths[ncol], right = right))
        print(" ".join(line))
        if nrow == 0:
            print("-" * (sum(widths.values()) + len(widths) - 1))


def main():
    file_names = sys.argv[1:]
    runs = parse_and_validate(file_names)
    confs, values = extract_values(runs)
    table = to_table(confs, file_names, values)
    print_table(table)


if __name__ == "__main__":
    main()
