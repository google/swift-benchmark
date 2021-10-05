# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""A command-line tool to compare benchmark results in json format.

This tool lets one to see the difference between two independent runs
of the same benchmarks. This is is convenient whenever one develops a
perfromance fix and wants to find out if a particula change brings
measurable performance improvement.

For example:

    $ swift run -c release BenchmarkMinimalExample --format json > a.json

    $ swift run -c release BenchmarkMinimalExample --format json > b.json

    $ python Scripts/compare.py a.json b.json
    benchmark                    column            a        b       %
    -----------------------------------------------------------------
    add string no capacity       time       37099.00 37160.00   -0.16
    add string no capacity       std            1.13     1.30  -15.27
    add string no capacity       iterations 37700.00 37618.00    0.22
    add string reserved capacity time       36730.00 36743.00   -0.04
    add string reserved capacity std            1.12     2.42 -116.30
    add string reserved capacity iterations 38078.00 38084.00   -0.02
    -----------------------------------------------------------------
                                 time                           -0.10
                                 std                           -57.90
                                 iterations                      0.10

Here one can see an output that compares two indepdendant runs `a` and
`b` and concludes that they only differ in 0.1%, and are thus probably
identical results.

One can filter out the results in the comparison by either the benchmark
name using `--filter` and `--filter-not` flags, and also by the column
of the json output using `--columns`.
"""

import argparse
from collections import defaultdict
import json
import re


def require(cond, msg):
    """Fails with a message if condition is not true."""

    if not cond: raise Exception(msg)


def validate(file_name, parsed):
    """Validates that given json object is a valid benchmarks result."""

    require("benchmarks" in parsed,
            "{}: missing key 'benchmarks'.".format(file_name))
    require(len(parsed["benchmarks"]) > 0,
            "{}: must have at least one benchmark.".format(file_name))

    for i, benchmark in enumerate(parsed["benchmarks"]):
        require("name" in benchmark,
                "{}: benchmark #{}: missing key 'name'.".format(file_name, i))

        for k, v in benchmark.items():
            if k == "name": continue
            is_num = isinstance(v, int) or isinstance(v, float)
            template = "{}: benchmark #{}: values must be numbers."
            require(is_num, template.format(file_name, i))


def parse_and_validate(args):
    """Parse command-line args, parse given json files and validate their contents."""

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
    """Returns a predicate used to filter benchmark columns based on cli args."""

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
    """Collect benchmark values for the comparison, excluding filtered out columns."""

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
    """Compute geometric mean for the given sequence of values."""

    product = 1.0
    for value in values:
        product *= value
    return product**(1.0 / len(values))


def to_table(confs, args, values):
    """Compute a table of relative results across all input files."""

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
    """Pad base string with given fill until count, on either left or right."""

    while len(base) < count:
        if right:
            base += fill
        else:
            base = fill + base
    return base


def print_table(table):
    """Pretty print results table as aligned human-readable text."""

    # Collect width of each max column.
    widths = defaultdict(lambda: 0)
    for row in table:
        for ncol, col in enumerate(row):
            widths[ncol] = max(widths[ncol], len(str(col)))

    # Print results as an aligned text to stdout.
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
    """Parse command-line flags into a configuration object, and return it."""

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
    """Command-line entry-point."""

    args = parse_args()
    runs = parse_and_validate(args)
    confs, values = collect_values(args, runs)
    table = to_table(confs, args, values)
    print_table(table)


if __name__ == "__main__":
    main()
