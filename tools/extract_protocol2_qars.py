#!/usr/bin/env python3
"""Extract Protocol 2 Quartus archives as isolated, reviewable snapshots."""

from __future__ import annotations

import argparse
import json
from pathlib import Path, PurePosixPath
import struct
import zlib


SKIP_NAMES = {"qar_info.json", "zlib_out_time_stamp_tmp.tmp"}


def read_exact(stream, size: int) -> bytes:
    data = stream.read(size)
    if len(data) != size:
        raise ValueError("truncated QAR archive")
    return data


def extract_archive(archive: Path, output: Path, *, overwrite: bool) -> int:
    output.mkdir(parents=True, exist_ok=True)
    written = 0
    with archive.open("rb") as stream:
        magic, count = struct.unpack("<HH", read_exact(stream, 4))
        if magic != 0x0271:
            raise ValueError("unsupported QAR signature")

        for _ in range(count):
            data_len, _flags, name_len = struct.unpack("<IHH", read_exact(stream, 8))
            name = read_exact(stream, name_len).decode("utf-8")
            compressed = read_exact(stream, data_len)
            relative = PurePosixPath(name)
            if relative.is_absolute() or ".." in relative.parts or not relative.parts:
                raise ValueError(f"unsafe archive path: {name!r}")
            if relative.name in SKIP_NAMES:
                continue

            destination = output.joinpath(*relative.parts)
            if not destination.resolve().is_relative_to(output.resolve()):
                raise ValueError(f"archive path escapes output directory: {name!r}")
            if destination.exists() and not overwrite:
                raise FileExistsError(f"refusing to overwrite {destination}")

            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(zlib.decompress(compressed))
            written += 1

        if stream.read(1):
            raise ValueError("unexpected trailing bytes after QAR entries")
    return written


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "protocol2_dir",
        nargs="?",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "Protocol 2",
        help="Protocol 2 directory (defaults to the sibling repository directory)",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="replace files in existing snapshot directories",
    )
    args = parser.parse_args()
    root = args.protocol2_dir.resolve()
    if not root.is_dir():
        parser.error(f"not a directory: {root}")

    archives = sorted(
        path for path in root.rglob("*.qar") if "source" not in path.relative_to(root).parts
    )
    results = []
    for archive in archives:
        snapshot = archive.parent / "source" / archive.stem
        written = extract_archive(archive, snapshot, overwrite=args.overwrite)
        results.append(
            {
                "archive": archive.relative_to(root).as_posix(),
                "snapshot": snapshot.relative_to(root).as_posix(),
                "files": written,
            }
        )
        print(f"{archive.relative_to(root)} -> {snapshot.relative_to(root)} ({written} files)")

    print(json.dumps({"archives": len(results), "extracted_files": sum(r["files"] for r in results)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())