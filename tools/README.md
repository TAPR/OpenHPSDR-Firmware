# Protocol 2 Source Extraction

`extract_protocol2_qars.py` discovers Quartus `.qar` archives below
`Protocol 2/`, extracts each archive into a sibling `source/` directory, and
keeps each archive as an isolated snapshot named after its archive stem. This
preserves separate project families such as Hermes 100T/1000T and Atlas
Mercury/Metis instead of merging files based only on their parent board name.

Run it from the repository root:

```sh
python3 tools/extract_protocol2_qars.py
```

The extractor validates the QAR signature, entry boundaries, zlib payloads,
and output paths. It omits `qar_info.json`, which contains machine-specific
paths and host metadata, and `zlib_out_time_stamp_tmp.tmp`, which is temporary
unpacker output. It does not invoke Quartus or access network or radio
hardware.

This supports the source-browsability request in
[issue #2](https://github.com/TAPR/OpenHPSDR-Firmware/issues/2). In the issue's
[maintainer comment](https://github.com/TAPR/OpenHPSDR-Firmware/issues/2#issuecomment-5837423344),
the proposed approach is to unarchive each board's QAR files and check the
resulting source into a source directory so source changes can be traversed.
The generated snapshots are for the QAR archives currently retained in the
repository; they are not claimed to be the earliest source ever produced.