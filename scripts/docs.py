#!/usr/bin/env python3

import os
import re
import json
import subprocess


DOCS_DIR = "./docs"
BUILD_DIR = "./build/docs"

INSTITUTE = "Gerber Prototyping"
LOGO = "./docs/figures/GerberPrototypingBulb.png"
AUTHORS = ["Andrew Gerber"]


def consolidate(sections:dict, parent_section:str) -> str:
    content = ""
    i = 1
    for filename,subsections in sections.items():
        depth = len(parent_section.split(".")) if parent_section else 0
        section_num = f"{parent_section}.{i}" if parent_section else str(i)
        if 1 == len(filename.split(".")):
            # Section title only
            content += f"#{'#'*depth} {filename}\n\n"
        else:
            # Append section content
            with open(f"{DOCS_DIR}/{filename}", 'r', encoding='UTF-8') as file:
                buff = file.read()
                # set heading depth
                buff = re.sub(r"^(#+)", fr"{'#'*depth}\1", buff, flags=re.MULTILINE)
                # re-number tables and figures
                buff = re.sub(r"((?:[Ff]igure|[Tt]able)) (\d+)", fr"\1 {section_num}.\2", buff)
                buff += "\n\n\\clearpage\n\n"
                content += buff
        if subsections:
            content += consolidate(subsections, section_num)
        i += 1
    return content

def format(content:str) -> str:
    # Fix some relative paths
    content = content.replace("../figures","./figures")
    # Some special unicode characters
    content = content.replace("│","|")
    content = content.replace("─","-")
    content = content.replace("├","|")
    content = content.replace("└","|")
    # Convert some HTML tags into latex
    # content = content.replace("<br>", "")
    return content


def main() -> int:
    try:
        os.mkdir(BUILD_DIR)
    except FileExistsError:
        pass
    with open(f"{DOCS_DIR}/pdf.json", 'r', encoding='UTF-8') as json_file:
        json_data = json.load(json_file)
    for filename,meta in json_data.items():
        print()
        print(f"Building {filename}")
        if not 'sections' in meta:
            print(f"No 'sections' found for {filename}")
            return 1
        sections = meta['sections']

        # Consolidate markdown
        print("  Consolidating markdown files")
        content = consolidate(sections, "")
        content = format(content)
        md_filename = f"{BUILD_DIR}/{filename}.md"
        pdf_filename = f"{filename}.pdf"
        with open(md_filename, 'w', encoding='UTF-8') as md_file:
            md_file.write(content)
        # Generate PDF
        print("  Converting to PDF")
        cmd  = f"pandoc {md_filename} -o {pdf_filename}"
        # cmd += f" --pdf-engine=xelatex"
        cmd += f" --template {os.path.abspath(DOCS_DIR)}/template.tex"
        cmd += f" --highlight-style {os.path.abspath(DOCS_DIR)}/style.theme"
        cmd += f" --resource-path {DOCS_DIR}"
        cmd +=  " --toc --toc-depth 3"
        cmd +=  " --number-sections"
        cmd +=  " --fail-if-warnings"
        # cmd +=  " -V documentclass:article"
        cmd +=  " -V documentclass:scrartcl"
        # cmd += f" -V include-before:'{DOCS_DIR}/datasheet.tex'"
        cmd +=  " -V geometry:margin=1in"
        cmd +=  " -V fontsize:12pt"
        cmd +=  " -V hyperrefoptions:linktoc=all"
        cmd +=  " -V pagestyle:headings"
        cmd +=  " -V colorlinks=true"
        cmd +=  " -V linkcolor=blue"
        cmd +=  " -V urlcolor=blue"
        # cmd +=  " -V toccolor=gray"
        cmd += f" -V institute:'{INSTITUTE}'"
        cmd += f" -V logo:'{LOGO}'"
        # Get title
        if 'title' in meta:
            title = meta['title']
        else:
            title = re.sub(r"_", " ", filename)
        cmd += f" -V title:'{title}'"
        if 'subtitle' in meta:
            cmd += f" -V subtitle:'{meta['subtitle']}'"
        for author in AUTHORS:
            cmd += f" -V author:'{author}'"
        rval = subprocess.call(cmd, shell=True)
        if rval:
            print("Failed to generate PDF")
            return rval
    return 0

if __name__ == "__main__":
    exit(main())
