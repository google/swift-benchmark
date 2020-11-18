import sys
import json
from pprint import pprint
from collections import defaultdict
import argparse
import re


def require(cond, msg):
    if not cond: raise Exception(msg)


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


def parse_and_validate(args):
    runs = []

    for file_name in args.file_names:
        with open(file_name) as f:
            parsed = None
            try:
                parsed = json.load(f)
            except Exception as err:
                raise Exception("failed to parse json: {}".format(err))
            validate(file_name, parsed)
            runs.append((file_name, parsed))

    return runs


def benchmark_predicate(args):
    include = lambda x: True

    if args.filter:
        regex = re.compile(args.filter)
        prev_include = include
        include = lambda x: regex.search(x) is not None and prev_include(x)

    if args.filter_not:
        regex = re.compile(args.filter_not)
        prev_include = include
        include = lambda x: regex.search(x) is None and prev_include(x)

    return include


def collect_values(args, runs):
    baseline_name, baseline = runs[0]

    include_benchmark = benchmark_predicate(args)
    include_column = lambda x: args.columns is None or x in args.columns

    confs = []
    values = {}

    for benchmark in baseline["benchmarks"]:
        benchmark_name = benchmark["name"]
        if not include_benchmark(benchmark_name):
            continue
        for column in benchmark.keys():
            if column == "name":
                continue
            if not include_column(column):
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


def geomean(values):
    product = 1.0
    for value in values:
        product *= value 
    return product**(1.0/len(values))


def to_table(confs, args, values):
    baseline_file_name = args.baseline
    rows = [] 

    # Header row.
    header = []
    header.append("benchmark")
    header.append("column")
    for (n, file_name) in enumerate(args.file_names):
        name = file_name.replace(".json", "")
        header.append(name)
        if n != 0:
            header.append("%")
    rows.append(header)

    # Body rows.
    relative_values = defaultdict(lambda: defaultdict(list))
    for conf in confs:
        bench_name, column = conf
        row = []
        row.append(bench_name)
        row.append(column)
        for n, file_name in enumerate(args.file_names):
            base_value = values[conf][baseline_file_name]
            value = values[conf][file_name]
            row.append("{:.2f}".format(value))
            if n != 0:
                relative = value/base_value
                relative_values[column][file_name].append(relative)
                relative_percentage = (1 - relative ) * 100
                row.append("{:.2f}".format(relative_percentage))
        rows.append(row)

    # Compute totals for each columsn as a geomean of all relative results.
    cols = []
    geomean_values = defaultdict(dict) 
    for (_, col) in confs:
        if col not in cols:
            cols.append(col)
            for n, file_name in enumerate(args.file_names):
                if n != 0:
                    vs = relative_values[col][file_name]
                    geomean_values[col][file_name] = geomean(vs)

    for col in cols:
        row = []
        row.append("")
        row.append(col)
        for n, file_name in enumerate(args.file_names):
            row.append("")
            if n != 0:
                value = geomean_values[col][file_name]
                percentage = (1 - value) * 100
                row.append("{:.2f}".format(percentage))
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
    # Collect width of each max column.
    widths = defaultdict(lambda: 0)
    for row in table:
        for ncol, col in enumerate(row):
            widths[ncol] = max(widths[ncol], len(str(col)))

    # Print results as an aligned human-readable table.
    totals = False
    for nrow, row in enumerate(table):
        if row[0] == '' and not totals:
            print("-" * (sum(widths.values()) + len(widths) - 1))
            totals = True
        line = []
        for ncol, col in enumerate(row):
            right = ncol == 0 or ncol == 1
            line.append(pad(str(col), " ", widths[ncol], right = right))
        print(" ".join(line))
        if nrow == 0:
            print("-" * (sum(widths.values()) + len(widths) - 1))


def parse_args():
    parser = argparse.ArgumentParser(description="Compare multiple swift-benchmark json files.")
    parser.add_argument("baseline", help="Baseline json file to compare against.")
    parser.add_argument("candidate", nargs="+", 
                        help="Candidate json files to compare against baseline.") 
    parser.add_argument("--filter", help="Only show benchmarks that match the regular expression.")
    parser.add_argument("--filter-not", help="Exclude benchmarks whose names match the regular expression.")
    parser.add_argument("--columns", help="A comma-separated list of columns to show.")
    args = parser.parse_args()
    args.file_names = [args.baseline]
    args.file_names.extend(args.candidate)
    if args.columns is not None:
        args.columns = set(args.columns.split(","))
    return args


def main():
    args = parse_args()
    runs = parse_and_validate(args)
    confs, values = collect_values(args, runs)
    table = to_table(confs, args, values)
    print_table(table)


if __name__ == "__main__":
    main()
