# Sylvan Project Memory

## Installed Tools

### GeMoMa 1.9 (Homology-based gene prediction)
- **Environment**: `micromamba activate gemoma`
- **Env path**: `/data/gpfs/assoc/pgl/bin/conda/conda_envs/gemoma/`
- **Version**: 1.9 (manually upgraded from bioconda 1.7.1)
- **JAR**: `$CONDA_PREFIX/share/gemoma-1.7.1-0/GeMoMa-1.9.jar`
- **Dependencies**: Java 11 (OpenJDK 11.0.9.1), mmseqs2 13.45111
- **Usage**: `GeMoMa GeMoMaPipeline t=target.fa s own a=ref.gff3 g=ref.fa`
- **Install details**: See [gemoma-install.md](gemoma-install.md)
- **Note**: Wrapper script (`GeMoMa`) was edited to point to 1.9 JAR; old 1.7.1 JAR preserved

### EDTA 2.2.2 (TE Annotator)
- **Container**: `/data/gpfs/home/wyim/scratch/singularity/EDTA.sif` (1.6GB)
- **Source**: `docker://quay.io/biocontainers/edta:2.2.2--hdfd78af_1`
- **Usage**: `singularity exec EDTA.sif EDTA.pl --genome <fa> --species others --step all --threads 32 --anno 1`
- **Run scripts**: `run_scripts/run_EDTA.sh` (batch), `run_scripts/run_EDTA_{Species}.sh` (individual)
- **Output**: `edta_output/{Species}/` → `*.mod.MAKER.masked` (softmasked genome)

### BRAKER3 v3.0.8 (Gene Prediction - ETP mode)
- **Container**: `~/scratch/singularity/braker3.sif` (~2.3GB)
- **Source**: `docker://teambraker/braker3:latest`
- **Mode**: ETP (RNA-Seq + Proteins) — `--bam` + `--prot_seq` 동시 제공 시 자동
- **UTR**: `--UTR=on` 사용 (컨테이너에서 `--addUTR=on`은 미지원 — Java/GUSHR 미포함)
- **AUGUSTUS config**: writable 복사 필요 → `${SYLVAN}/braker3_augustus_config/`
- **GeneMark 키**: v3.0.4+ 이후 불필요
- **Guide**: `${SYLVAN}/BRAKER3_guide.md`
- **Output**: `braker3_output/{Species}/`

## User Preferences
- Language: Korean preferred
- micromamba (v2.3.2) used for conda env management
- Singularity 이미지 저장 경로: `~/scratch/singularity/` (항상 이 경로 사용)

## Sylvan Pipeline Structure
- **Snakefile_annotate**: 메인 annotation 파이프라인 (genome → Miniprot/GETA/Helixer/Liftoff → EVM 통합)
  - config: `Sylvan/config/config_annotate.yml`, env var `SYLVAN_CONFIG`로 override 가능
  - 출력: `results/` (env var `SYLVAN_RESULTS_DIR`로 override)
  - Singularity 이미지 경로를 absolute로 resolve
- **Snakefile_filter**: Random Forest 기반 gene model 필터링
  - config: `config_filter.yml`, env var `SYLVAN_FILTER_CONFIG`
  - STAR → RSEM → RNA-Seq evidence 활용, paired-end `_1/_2` 또는 `_R1/_R2` 지원
- **Snakefile_filter_score**: 점수 기반 필터링 변형
- **주요 Python 스크립트**: `Sylvan/bin/` 내 16개 (Filter.py, TidyGFF.py, Pick_Primaries.py, combine_genemodel.py, gff_to_evm.py, miniprot2Genewise.py 등)

## Code Patterns
- GFF3 파싱: `parse_attributes()` 함수로 attribute 딕셔너리 변환 패턴 반복 사용
- defaultdict 활용: transcript→gene 매핑, exon/CDS 카운팅에 일관적 사용
- SLURM sbatch wrapper: 공통 옵션 파싱 (`-A`, `-p`, `-c`, `--mem`, `--time`) + lineage 플래그 (`-V`, `-L`, `-E`)
- Singularity exec: 모든 도구 실행에 컨테이너 사용 (`singularity exec $image cmd`)
- gffcompare stats 파싱: 라인 인덱스 하드코딩으로 recall/precision/F1 추출

## Known Issues (2026-03 코드 리뷰)
- **scrapeGffCompare.py 3중복**: `gffcompare/`, `intermidiateOutputs_gffcompare/`, `genome/gff3/no_utr/` 에 거의 동일 코드
- **countSingleExonGenes.py 2중복**: `gffcompare/`, `genome/gff3/`
- **runBusco.sh 3중복**: `busco/`, 루트, `new_busco/` (singularity 경로만 다름)
- **수정 완료**: `--time` → `tme` 변수 버그, `busco_lineage` 재초기화 버그, 디버그 print 제거, 주석 코드 정리, sbatch --wrap 따옴표

## File Dependencies
- `Snakefile_annotate` → config_annotate.yml → genome.fa, proteins.fa, RNA-Seq BAM
- `Snakefile_filter` → config_filter.yml → annotation GFF3, RNA-Seq FASTQ, Pfam HMM DB
- `Filter.py` ← Snakefile_filter (Random Forest 모델 학습/적용)
- `gff_to_evm.py`, `combine_genemodel.py` ← Snakefile_annotate (EVM 입력 준비)
- `scrapeGffCompare.py` ← gffcompare .stats 파일 (벤치마크 결과 파싱)
- `runBusco.sh` ← protein.fa 또는 GFF3+genome (BUSCO 품질 평가)
