#!/usr/bin/env python3
"""
X - A simple command-line utility.
"""

import argparse
import sys


def main():
    parser = argparse.ArgumentParser(description="X - A simple command-line utility")
    parser.add_argument("args", nargs="*", help="Arguments to process")

    args = parser.parse_args()

    if args.args:
        print(f"Arguments: {' '.join(args.args)}")
    else:
        print("No arguments provided. Use -h for help.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
