#!/usr/bin/env python3

import os
import sys
import re
import argparse
from typing import List
from tabulate import tabulate

PROJ_DIR=os.path.dirname(os.path.abspath(f"{sys.argv[0]}/../"))
MAX_MODULE_NAME_LENGTH=24


parser = argparse.ArgumentParser()
parser.add_argument("top", type=str,
                    help="name of top module to analyze")
parser.add_argument("--max", type=int, default=10,
                    help="maximum number of paths to show (default: 10)")
parser.add_argument("-a","--all", dest="all", action="store_true",
                    help="disable max number of paths limit")
parser.add_argument("-v","--verbose", dest="verbose", action="store_true",
                    help="label startpoint and endpoint")
parser.add_argument("-vv", dest="verbose2", action="store_true",
                    help="show path details")
parser.add_argument("-vvv", dest="verbose3", action="store_true",
                    help="show extensive path details")
parser.add_argument("--no-graph", dest="noGraph", action="store_true",
                    help="Do not show delay visualization graph")
parser.add_argument("--sel", metavar="ID", type=int, nargs="*",
                    help="Select path by id")

args = parser.parse_args()
if args.noGraph:
    args.verbose2 = True
if args.verbose3:
    args.verbose2 = True
if args.verbose2:
    args.verbose = True

BUILD_DIR=f"{PROJ_DIR}/build/synth/{args.top}"
TIMING_REPORT=f"{BUILD_DIR}/pt_timing_report.txt"


class Module:
    def __init__(self, name:str) -> None:
        self.name = name
        self.delay = 0.0
        self.cells = 0
        self.raw = []
    def addCell(self, line:str) -> None:
        line = line.strip()
        raw = (
            re.search(r"^\S*(\s\(\S*\)?)", line)[0],
            float(re.search(r"\d+\.\d+", line)[0])
        )
        self.delay += raw[1]
        self.cells += 1
        self.raw.append(raw)
    def asList(self) -> List[str]:
        return [
            self.name,
            f"{self.delay:0.2f}",
            "",
            f"{self.cells} cells"
        ]

class Path:
    def __init__(self, startpoint:str):
        self.startpoint = startpoint
        self.endpoint = ""
        self.modules = []
        self.delay = -1.0
        self.cells = 0
    def addEndpoint(self, endpoint:str) -> None:
        self.endpoint = endpoint
    def addModule(self, module:Module) -> None:
        self.cells += module.cells
        self.modules.append(module)
    def tabulate(self, visualize=True) -> str:
        arr = []
        for module in self.modules:
            x = module.asList()
            if visualize:
                # add small visualization
                width = int(20*module.delay)
                x.append(f"{'*'*width}")
            arr.append(x)
        arr.append(["TOTAL",f"{self.delay:.2f}", "", f"{self.cells} cells"])
        table = tabulate(arr, tablefmt="plain")
        ret = "".join("  "+line for line in table.splitlines(True)) # add indent
        return ret
    def tabulateVerbose(self) -> str:
        arr = []
        for module in self.modules:
            for raw in module.raw:
                arr.append([raw[0], f"{raw[1]:.2f}"])
        arr.append(["TOTAL", f"{self.delay:.2f}"])
        table = tabulate(arr, tablefmt="plain")
        ret = "".join("    | "+line for line in table.splitlines(True)) # add indent
        return ret
    def visualize(self) -> str:
        ret = ""
        for i in range(3):
            if (i == 0):
                ret += "┏"
            elif (i == 1):
                ret += "┃"
            else:
                ret += "┗"
            for module in self.modules:
                width = int(60*module.delay)
                w = max(0, width - 2) # inner dimension
                if (i == 1):
                    # Middle
                    # Print module name
                    # ret += "┃"
                    name = module.name
                    isModule = not re.search(r"^U\d+", name)
                    if not isModule:
                        name = "╍"*w
                    name = re.sub(r"genblk\d_", "", name) # remove leading genblk
                    name = re.sub(r"_module$", "", name) # remote trailing module
                    name = name[:w] # truncate to fit width
                    padding1 = int( (w - len(name)) / 2 )
                    padding2 = w-len(name)-padding1
                    ret += " "*padding1
                    ret += name
                    ret += " "*padding2
                    if isModule:
                        ret += "┃"
                    else:
                        ret += "┫"
                elif (i == 0):
                    # Top
                    ret += "━"*(width-2)
                    ret += "┳"
                else:
                    # Bottom
                    ret += "━"*(width-2)
                    ret += "┻"
            ret = ret[:-1] # remove last character
            if (i == 0):
                ret += "┓"
            elif (i == 1):
                ret += "┃"
            else:
                ret += "┛"
            ret += "\n"
        return ret[:-1] # remove trailing newline




def parseTimingReport(filename:str) -> List[Path]:
    with open(filename, 'r') as file:
        paths = [] # array of Paths
        path = None # current path
        module = None # current module
        state = 'startpoint'
        for line in file.readlines():
            # if (len(paths) >= args.max):
            #     break
            line = line.strip()
            if (state == 'startpoint'):
                # Find startpoint
                if (line.startswith("Startpoint")):
                    path = Path( re.sub(r"Startpoint:\s*", "", line) )
                    module = Module(re.search(r"^[^/]*", path.startpoint)[0])
                    state = 'endpoint'
            elif (state == 'endpoint'):
                # Find endpoint
                if (line.startswith("Endpoint")):
                    path.addEndpoint( re.sub(r"Endpoint:\s*", "", line) )
                    state = 'first_hop'
            elif (state == 'first_hop'):
                # Skip ahead to startpoint
                if (line.startswith(module.name)):
                    #module.addCell(parseDelay(line))
                    module.addCell(line)
                    state = 'hops'
            elif (state == 'hops'):
                # Progress through delay path
                if (line.startswith("data arrival time")):
                    # Reached end of path
                    # Get total delay
                    path.delay = float(re.sub(r"data arrival time\s*","",line))
                    path.addModule(module)
                    # Start looking for next delay path
                    paths.append(path)
                    state = 'startpoint'
                else:
                    # Get this cell's delay
                    curr = re.search(r"^[^/]*", line)[0]
                    if (curr != module.name):
                        # Next module
                        path.addModule(module)
                        module = Module(curr)
                    module.addCell(line)
        return paths




def main() -> None:
    print()
    print(f"Top module: {args.top}")
    print()
    paths = parseTimingReport(TIMING_REPORT)
    if args.sel:
        ids = args.sel
    else:
        if args.all:
            ids = range(len(paths))
        else:
            ids = range(min( len(paths), args.max ))
    for i in ids:
        path = paths[i]
        if args.verbose:
            label = f"#{i}  {path.startpoint} -> {path.endpoint}    {path.delay:.2f}"
            print(label)
            if args.verbose2:
                print("-"*len(label))
                if args.verbose3:
                    print(path.tabulateVerbose())
                else:
                    print(path.tabulate(visualize=(not args.noGraph)))
            if not args.noGraph:
                print(path.visualize())
            print()
        else:
            # print minimal
            indent = 6
            id = (f"#{i}")
            id = (id + (" ")*indent)[:indent]
            graph = path.visualize().splitlines(True)
            graph[0] = (" "*indent) + graph[0]
            graph[1] = id + graph[1]
            graph[2] = (" "*indent) + graph[2]
            print("".join(graph))


if __name__ == "__main__":
    main()
