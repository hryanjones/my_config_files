# Global Claude Instructions

## JSON Analysis

When analyzing or querying JSON data, prefer `jq` over writing a Python script unless the transformation is complex enough that jq syntax would be harder to read.

## CSV/TSV Analysis

When reading or transforming CSV/TSV data, prefer `mlr` (Miller) over writing a Python script unless the transformation is too complex for miller syntax.
