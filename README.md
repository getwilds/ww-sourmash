# ww-sourmash: Sourmash Sketch and Search Workflow
[![Project Status: Experimental – Useable, some support, not open to feedback, unstable API.](https://getwilds.org/badges/badges/experimental.svg)](https://getwilds.org/badges/#experimental)

## Overview
This workflow uses Sourmash to generate MinHash signatures for sequence files and perform similarity searches between them. It's implemented in WDL (Workflow Description Language) and designed to run with Cromwell or other WDL-compatible workflow engines.

## Prerequisites
- Cromwell or another WDL-compatible workflow engine
- Docker (the workflow uses the `getwilds/sourmash:4.8.2` container)
- Sufficient disk space for your sequence files and their signatures

## Workflow Structure
The workflow consists of two main steps:
1. **SketchBothSequences**: Generates MinHash signatures for both query and database sequences
2. **RunSourmashSearch**: Performs similarity search between the generated signatures

## Input Files
Create a JSON file (e.g., `inputs.json`) with the following structure:
```json
{
    "SourmashSketchAndSearch.query_fastq": "/path/to/query.fastq.gz",
    "SourmashSketchAndSearch.database_fasta": "/path/to/database.fa.gz"
}
```

## Workflow Options
Create a JSON file (e.g., `options.json`) to configure workflow execution:
```json
{
    "workflow_failure_mode": "ContinueWhilePossible",
    "write_to_cache": true,
    "read_from_cache": true,
    "default_runtime_attributes": {
        "maxRetries": 1
    },
    "final_workflow_outputs_dir": "/path/to/outputs/",
    "use_relative_output_paths": true
}
```

### Options Explained
- `workflow_failure_mode`: Determines how the workflow handles task failures
- `write_to_cache`: Enables caching of task outputs for future runs
- `read_from_cache`: Allows reuse of cached outputs from previous runs
- `maxRetries`: Number of times to retry failed tasks
- `final_workflow_outputs_dir`: Directory for final workflow outputs
- `use_relative_output_paths`: Maintains relative path structure in output directory

## Default Parameters
The workflow includes several default parameters that can be overridden in your inputs JSON:
- `ksize`: "31" (k-mer size for sketching and searching)
- `threshold`: 0.08 (minimum similarity threshold for reporting matches)
- `sketch_type`: "dna" (molecule type: dna, protein, dayhoff, hp, or nucleotide)
- `scaled`: true (use scaled MinHash)
- `scale_factor`: 1000 (scale factor for scaled MinHash)

## Running the Workflow

### With Cromwell
```bash
java -jar cromwell.jar run \
    sourmash-search-workflow.wdl \
    -i inputs.json \
    -o options.json
```

### Workflow Outputs
The workflow produces three main outputs:
1. Query sequence signature file (`.sig`)
2. Database sequence signature file (`.sig`)
3. Search results file (`search_results.csv`)

## Resource Requirements
Default resource allocations per task:
- **SketchBothSequences**:
  - Memory: 4GB
  - CPU: 2
  - Disk: 50GB SSD
- **RunSourmashSearch**:
  - Memory: 4GB
  - CPU: 1
  - Disk: 50GB SSD

Adjust these values in the WDL file based on your input data sizes and computational resources.

## Troubleshooting

### Common Issues
1. **Insufficient Disk Space**: Increase `disk_size_gb` in task runtime sections
2. **Memory Errors**: Adjust `memory_gb` based on input file sizes
3. **Docker Pulling Failures**: Ensure access to Docker Hub and correct image version

### Task Retry Behavior
- Tasks will retry once on failure (configurable via `maxRetries`)
- The workflow continues executing possible tasks if one fails (`ContinueWhilePossible` mode)

## Contributing
Feel free to submit issues and enhancement requests to improve this workflow.

## License
Distributed under the MIT License. See `LICENSE` for details.


