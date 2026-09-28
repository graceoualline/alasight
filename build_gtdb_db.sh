#!/usr/bin/env bash
# Build a full GTDB r214 database
#
# Usage:  bash build_gtdb_db.sh <workdir> [threads]

set -euo pipefail

WORK="${1:?usage: build_gtdb_db.sh <workdir> [threads]}"
THREADS="${2:-$(nproc)}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REF="${REPO_DIR}/references-compressed"

mkdir -p "${WORK}"; cd "${WORK}"
echo "workdir: ${WORK}   threads: ${THREADS}"

# GTDB representative genomes, use extracted dir if present, else tarball, else download
if [ -d gtdb_genomes_reps_r214 ]; then
  echo "Genomes already extracted, skipping download."
elif [ -f gtdb_genomes_reps_r214.tar.gz ]; then
  echo "Tarball present, extracting..."
  tar xzf gtdb_genomes_reps_r214.tar.gz
else
  echo "Downloading GTDB r214 genomes (tens of GB)..."
  curl -L -O "https://data.gtdb.ecogenomic.org/releases/release214/214.1/genomic_files_reps/gtdb_genomes_reps_r214.tar.gz"
  echo "Extracting genomes..."
  tar xzf gtdb_genomes_reps_r214.tar.gz
fi

# genome list
if [ ! -s gtdb_list.txt ]; then
  find "$(pwd)/gtdb_genomes_reps_r214" -name '*.fna.gz' > gtdb_list.txt
fi
echo "    $(wc -l < gtdb_list.txt) genomes listed"

# build the database
echo "Building database..."
"${REPO_DIR}/alasight.py" build-db \
  -i gtdb_list.txt \
  -d database -tr tree \
  -n "${REF}/TimeTree_v5_Final.nwk" \
  -s "${REF}/gtdbr214rep_to_ncbi.tsv" \
  -t "${THREADS}" --representatives --skani-sketch

echo "Query with:"
echo "     alasight.py run -d ${WORK}/database -q query.fna -o out_dir -t ${THREADS}"