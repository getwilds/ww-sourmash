version 1.0

# Workflow: SourmashSketchAndSearch
# Purpose: Generate MinHash signatures for sequence files and perform similarity searches
# Input: Two sequence files (query and database)
# Output: Signature files for both inputs and search results showing similarity matches
workflow SourmashSketchAndSearch {
    input {
        File query_fastq          # Input query sequence file (FASTA/FASTQ)
        File database_fasta       # Input database sequence file (FASTA/FASTQ)
        String ksize = "31"       # k-mer size for both sketch and search
        Float threshold = 0.08    # Minimum threshold for reporting matches
        String sketch_type = "dna"  # Molecule type: dna, protein, dayhoff, hp, or nucleotide
        Boolean scaled = true     # Use scaled MinHash (recommended for most use cases)
        Int scale_factor = 1000   # Scale factor for scaled MinHash (lower = more precise, higher = more memory efficient)
    }

    # Step 1: Generate MinHash signatures for both input sequences
    call SketchBothSequences {
        input:
            query_file = query_fastq,
            database_file = database_fasta,
            ksize = ksize,
            sketch_type = sketch_type,
            scaled = scaled,
            scale_factor = scale_factor,
            query_output_name = basename(query_fastq) + ".sig",
            database_output_name = basename(database_fasta) + ".sig"
    }

    # Step 2: Perform similarity search between the generated signatures
    call RunSourmashSearch {
        input:
            query_sig = SketchBothSequences.query_signature,
            database_sig = SketchBothSequences.database_signature,
            ksize = ksize,
            threshold = threshold
    }

    output {
        File query_signature = SketchBothSequences.query_signature
        File database_signature = SketchBothSequences.database_signature
        File search_results = RunSourmashSearch.results_file
    }
}

# Task: SketchBothSequences
# Purpose: Generate MinHash signatures for both query and database sequences in a single task
# Note: This combined task reduces workflow overhead compared to running two separate sketch tasks
task SketchBothSequences {
    input {
        File query_file
        File database_file
        String ksize
        String sketch_type
        Boolean scaled
        Int scale_factor
        String query_output_name
        String database_output_name
        
        # Runtime parameters - adjust based on input file sizes and complexity
        Int memory_gb = 4
        Int disk_size_gb = 50
        Int cpu = 2  # Using 2 CPUs since we're processing two files
    }

    command <<<
        # Enable error handling
        set -eo pipefail
        
        # Step 1: Generate signature for query file
        # The -p parameter sets both k-mer size and scaling/num parameters
        sourmash sketch \
            ~{sketch_type} \
            ~{query_file} \
            -p "k=~{ksize},~{if scaled then "scaled=" else "num="}~{scale_factor}" \
            -o ~{query_output_name}
            
        # Step 2: Generate signature for database file
        # Using identical parameters to ensure compatibility
        sourmash sketch \
            ~{sketch_type} \
            ~{database_file} \
            -p "k=~{ksize},~{if scaled then "scaled=" else "num="}~{scale_factor}" \
            -o ~{database_output_name}
    >>>

    output {
        File query_signature = query_output_name
        File database_signature = database_output_name
    }

    runtime {
        docker: "getwilds/sourmash:4.8.2"
        memory: "~{memory_gb}GB"
        cpu: cpu
        disks: "local-disk ~{disk_size_gb} SSD"
    }
}

# Task: RunSourmashSearch
# Purpose: Compare two signature files to find sequence similarities
# Output: CSV file containing similarity matches above the specified threshold
task RunSourmashSearch {
    input {
        File query_sig
        File database_sig
        String ksize
        Float threshold
        
        # Runtime parameters - adjust based on signature sizes and search complexity
        Int memory_gb = 4
        Int disk_size_gb = 50
        Int cpu = 1
    }

    command <<<
        # Enable error handling
        set -eo pipefail

        # Perform containment search between signatures
        # --containment flag calculates containment rather than jaccard similarity
        sourmash search \
            -k ~{ksize} \
            --threshold ~{threshold} \
            ~{query_sig} \
            ~{database_sig} \
            --containment \
            > search_results.csv
    >>>

    output {
        File results_file = "search_results.csv"
    }

    runtime {
        docker: "getwilds/sourmash:4.8.2"
        memory: "~{memory_gb}GB"
        cpu: cpu
        disks: "local-disk ~{disk_size_gb} SSD"
    }
}
