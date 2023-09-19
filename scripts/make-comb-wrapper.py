#!/usr/bin/env python3

import os
import sys
import re
import argparse


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=str,
                        help="path to combinatorial top module to wrap")
    parser.add_argument("--clk", type=str, default="clk",
                        help="name of clock input port (default: clk)")
    
    args = parser.parse_args()
    top = re.sub(r".*/", "", args.path)
    top = re.sub(r"\.sv", "", top)
    depend = re.sub(f".*/rtl/", "", args.path)
    
    with open(args.path) as top_module:
        buff = top_module.read()
    # add dependency
    buff = f"//depend {depend}\n{buff}"
    # remove comments except depend statements
    buff = re.sub(r"//(?!depend).*", "", buff)
    # remove body
    match = re.search(r"[\s\S]*?module[\s\S]*?;", buff)
    if match:
        buff = match.group(0)+"\n\n"
    else:
        print("No module found")
        sys.exit(1)
    # replace module name
    buff = re.sub(fr"module\s+{top}", f"module {top}_wrapper", buff)

    # get input port names
    inputs = re.findall(r"input[\s\S]*?([_a-zA-Z0-9]+)\s*[,\)]", buff)
    if not inputs:
        print("no input ports found")
        sys.exit(1)
    # get output ports
    matches = re.findall(r"output\s*([\s\S]*?)\s*[,\)]", buff)
    if not matches:
        print("no output ports found")
        sys.exit(1)
    # parse output port types and names
    outputs = []
    for match in matches:
        name = match.split()[-1]
        outputs.append({
            "name": name,
            "type": re.sub(fr"\s*{name}$", "", match)
        })

    # add clock port in missing
    if not args.clk in inputs:
        pattern = r"([ \t]*)input([\s\S]*?)([,\)])"
        replace = fr"\1input logic {args.clk},\n\1input\2\3"
        buff = re.sub(pattern, replace, buff, count=1)

    # create internal signals
    for output in outputs:
        buff += f"{output['type']} _{output['name']};\n"
    # register assignments
    buff += "\n"
    buff += f"always_ff @(posedge {args.clk}) begin\n"
    for output in outputs:
        buff += f"    {output['name']} <= _{output['name']};\n"
    buff += "end\n\n"
    # instantiate DUT
    buff += f"{top} #(\n"
    # if params:
    #     for param in params:
    #         buff += f"    .{param}({param}),\n"
    #     buff = buff[:-2] # remove trailing ','
    buff += f"\n) DUT (\n"
    for input in inputs:
        buff += f"    .{input}({input}),\n"
    for output in outputs:
        name = output['name']
        buff += f"    .{name}(_{name}),\n"
    buff = buff[:-2] # remove trailing ,
    buff += "\n);\n"
    buff += "\nendmodule\n"
    
    print(buff)
    
